module_info(
    name = "ubuntu",
    description = "Wraps Ubuntu's package feeds as yoe units, and ships an Ubuntu/glibc-side build toolchain (toolchain-glibc). Ubuntu is part of the Debian/dpkg/glibc family, so units here reuse the same debian_feed mechanism and carry the \"debian\" backend distro tag. The Ubuntu release pinned below MUST match the FROM ubuntu:<release> in containers/toolchain-glibc/Dockerfile — packages from these feeds are ABI- and signing-key-coupled to the toolchain libc.",
)

# Ubuntu shares Debian's apt/dpkg repository format, so it is wrapped
# with the same debian_feed() builtin rather than a bespoke one. Each
# call registers a synthetic module named "<parent>.<component>", so
# consumers reference packages via "ubuntu.main" in prefer_modules. The
# suite kwarg is feed configuration (it picks which on-disk Packages
# file is parsed); only one suite per project is supported, so it does
# not appear in the module identity.
#
# Units materialize lazily as the runtime closure references them —
# declaring a feed costs one Starlark call and the checked-in Packages
# text per arch, not tens of thousands of .star files. The units
# debian_feed synthesizes carry Distro = "debian"; that is the backend
# family tag (apt/dpkg/glibc rootfs assembly), and Ubuntu images set
# distro = "debian" for the same reason. The module name "ubuntu" is
# the identity used for prefer_modules and shadowing.
#
# ARCH SCOPE — amd64 only. Ubuntu splits its mirrors by architecture:
# amd64/i386 live on http://archive.ubuntu.com/ubuntu, while arm64 and
# the other ports arches live on http://ports.ubuntu.com/ubuntu-ports.
# debian_feed takes a single `url`, so one feed cannot span both. This
# feed serves amd64 from archive.ubuntu.com; an arm64 feed would be a
# second declaration pointed at ports.ubuntu.com once the build side
# learns to fetch per-arch debs from a different host.
#
# To refresh the in-tree Packages files from upstream after Ubuntu
# ships a point release or security update, run `yoe update-feeds` in
# this module's root. That fetches the feed's InRelease, verifies the
# signature against keys/ubuntu-archive-keyring.gpg, applies the
# fingerprint allow-list to any new key, and atomically rewrites
# feeds/<component>/<arch>/Packages.

_UBUNTU_MIRROR = "http://archive.ubuntu.com/ubuntu"
_UBUNTU_SUITE = "resolute"

debian_feed(
    name = "main",
    url = _UBUNTU_MIRROR,
    suite = _UBUNTU_SUITE,
    component = "main",
    arches = ["amd64"],
    index = "feeds/main",
    keyring = "keys/ubuntu-archive-keyring.gpg",
)
