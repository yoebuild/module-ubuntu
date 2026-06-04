# module-ubuntu

Wraps prebuilt Ubuntu packages as yoe units, and ships an Ubuntu/glibc
build toolchain. Ubuntu shares Debian's apt/dpkg/glibc machinery, so this
module uses the same `apt_feed()` builtin as `module-debian` — only with
`distro = "ubuntu"`: units fetch a binary `.deb` from a pinned Ubuntu
release, verify its SHA256 against the upstream-signed `Packages` catalog,
and republish it through yoe's project repo. A unit's "build" is just
extracting the deb's `data.tar` into `$DESTDIR`.

The module currently tracks Ubuntu **Resolute Raccoon (26.04 LTS)**. The
suite pinned in `MODULE.star` (`_UBUNTU_SUITE`) should track the
`FROM ubuntu:<release>` line in `containers/toolchain-glibc/Dockerfile`.

## Ubuntu is its own distro

`apt_feed(distro = "ubuntu", ...)` tags every materialized unit with
`Distro = "ubuntu"`, and the images set `distro = "ubuntu"`. That makes
Ubuntu a first-class distro in yoe's resolver — an Ubuntu image's closure
sees only Ubuntu-tagged units, so a project can declare both
`module-debian` and `module-ubuntu` and the two never collide. Under the
hood Ubuntu rides the shared apt/dpkg/glibc **backend** (mmdebstrap rootfs
assembly, `.deb` packaging, apt on device) that yoe applies to the whole
apt family; only the feed identity, suite, and mirror differ.

## Split mirrors (amd64 + arm64)

Ubuntu serves its architectures from two hosts: `amd64`/`i386` live on
`http://archive.ubuntu.com/ubuntu`, while `arm64` and the other ports
arches live on `http://ports.ubuntu.com/ubuntu-ports`. A single
`apt_feed` spans both via the optional `arch_urls` map, which overrides
the base `url` per architecture — used both when `yoe update-feeds`
fetches each arch's `Packages` and when the build downloads each `.deb`.
The InRelease is fetched once from `url` for signature verification; both
mirrors ship an InRelease signed by the same Ubuntu archive key.

## Layout

```
MODULE.star                # apt_feed(distro="ubuntu", ...) declaration
feeds/
  main/
    amd64/Packages         # checked-in catalog snapshot (archive.ubuntu.com)
    arm64/Packages         # checked-in catalog snapshot (ports.ubuntu.com)
keys/
  ubuntu-archive-keyring.gpg   # bootstrap keyring for InRelease verification
  allowed-fingerprints         # fingerprint allow-list for new keys
containers/
  toolchain-glibc.star     # Ubuntu/glibc build toolchain (provides "toolchain")
  toolchain-glibc/Dockerfile
classes/
  kernel.star              # ubuntu_kernel() -> linux-image-generic
images/
  base-image.star          # minimal bootable + SSH image
  ssh-image.star           # boot + SSH, no extra tooling
  dev-image.star           # base + diagnostic/editor userland
```

## Feeds

Each `apt_feed()` call registers a synthetic module named
`ubuntu.<component>` (e.g. `ubuntu.main`), so consumers reference packages
via `ubuntu.main` in `prefer_modules`. Declaring a feed costs one Starlark
call and the checked-in `Packages` text — units materialize lazily as the
runtime closure references them, so working memory tracks closure size,
not the full catalog.

To refresh the in-tree `Packages` files after Ubuntu ships a point release
or security update, run `yoe update-feeds --arch x86_64,arm64` in this
module's root. That fetches the feed's `InRelease`, verifies the signature
against `keys/ubuntu-archive-keyring.gpg`, applies the fingerprint
allow-list to any new key, and atomically rewrites
`feeds/main/<arch>/Packages`.

## Toolchain

`containers/toolchain-glibc` is the Ubuntu/glibc build toolchain. It
declares `provides = ["toolchain"]` and `distro = "ubuntu"`, wiring it
into yoe's distro-aware toolchain dispatch: Ubuntu images resolve the
virtual `toolchain` reference to this container, Debian images resolve it
to `module-debian`'s glibc toolchain, and Alpine images resolve it to
`module-alpine`'s `toolchain-musl`.

`module-debian` ships a `toolchain-glibc` under the same unit name. A
project that lists both modules gets deterministic last-module-wins
shadowing on that name; since both are interchangeable glibc/dpkg
toolchains (mmdebstrap pulls every target package from the project's own
repo, and the prebuilt-`.deb` units only extract data tars), either can
assemble either rootfs.

## Images

- `base-image` — the smallest closure that boots in QEMU and accepts an
  SSH login: kernel, systemd init, libc, coreutils, bash, dpkg/apt,
  openssh-server, and NetworkManager for DHCP.
- `ssh-image` — the same boot + SSH closure with no extra tooling, for an
  apples-to-apples size comparison against `module-alpine`'s `ssh-image`.
- `dev-image` — the base closure plus a diagnostic and editor userland
  (curl, htop, strace, less, file, procps, iproute2, ping, vim-tiny) so
  the device is usable for work over SSH.

The rootfs is assembled with `mmdebstrap --variant=custom`, which
installs exactly the listed closure and its hard dependencies — no
implicit Essential/Priority base. That keeps images minimal but means
the packages dpkg needs at configure time are listed explicitly in each
image (`dash`, `diffutils`, `libc-bin`, `base-files`, `base-passwd`).
