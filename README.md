# module-ubuntu

Wraps prebuilt Ubuntu packages as yoe units, and ships an Ubuntu/glibc
build toolchain. Ubuntu is part of the Debian/dpkg/glibc family, so this
module reuses the same machinery as `module-debian`: units fetch a binary
`.deb` from a pinned Ubuntu release, verify its SHA256 against the
upstream-signed `Packages` catalog, and republish it through yoe's
project repo. A unit's "build" is just extracting the deb's `data.tar`
into `$DESTDIR`.

The module currently tracks Ubuntu **Resolute Raccoon (26.04 LTS)**. The
suite pinned in `MODULE.star` (`_UBUNTU_SUITE`) should track the
`FROM ubuntu:<release>` line in `containers/toolchain-glibc/Dockerfile`.

## Architecture scope — amd64 only

Ubuntu splits its mirrors by architecture: `amd64`/`i386` live on
`http://archive.ubuntu.com/ubuntu`, while `arm64` and the other ports
arches live on `http://ports.ubuntu.com/ubuntu-ports`. The `debian_feed`
builtin takes a single `url`, so one feed cannot span both hosts. This
module's feed serves **amd64** from `archive.ubuntu.com`; `arm64`
support would be a second feed declaration pointed at the ports mirror.
`classes/kernel.star` maps only `x86_64` and fails loudly on other
arches with a pointer to the ports mirror.

## Layout

```
MODULE.star                # debian_feed() declaration (Ubuntu uses apt/dpkg too)
feeds/
  main/
    amd64/Packages         # checked-in catalog snapshot
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

Ubuntu's archive uses the same apt repository format as Debian, so feeds
are declared with the same `debian_feed()` builtin. Each call registers
a synthetic module named `ubuntu.<component>` (e.g. `ubuntu.main`), so
consumers reference packages via `ubuntu.main` in `prefer_modules`.
Declaring a feed costs one Starlark call and the checked-in `Packages`
text — units materialize lazily as the runtime closure references them,
so working memory tracks closure size, not the full catalog.

The units the feed synthesizes carry `Distro = "debian"` — that is yoe's
backend-family tag for the apt/dpkg/glibc rootfs path, not a claim about
the upstream archive. Ubuntu images set `distro = "debian"` for the same
reason: they ride the existing dpkg backend rather than a parallel one.

To refresh the in-tree `Packages` file after Ubuntu ships a point
release or security update, run `yoe update-feeds` in this module's
root. That fetches the feed's `InRelease`, verifies the signature
against `keys/ubuntu-archive-keyring.gpg`, applies the fingerprint
allow-list to any new key, and atomically rewrites
`feeds/main/<arch>/Packages`.

## Toolchain

`containers/toolchain-glibc` is the Ubuntu/glibc build toolchain. It
declares `provides = ["toolchain"]` and `distro = "debian"`, wiring it
into yoe's distro-aware toolchain dispatch: dpkg-family ("debian") images
resolve the virtual `toolchain` reference to this container, Alpine
images resolve it to `module-alpine`'s `toolchain-musl`.

A project that lists both `module-ubuntu` and `module-debian` gets
deterministic last-module-wins shadowing on the shared `toolchain-glibc`
name — whichever module is listed later in `PROJECT.star`'s `modules`
provides the toolchain. Either glibc toolchain can assemble either
rootfs (mmdebstrap pulls every target package from the project's own
repo, and the prebuilt-`.deb` units only extract data tars), so the
shared name is intentional.

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
