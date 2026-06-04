load("@core//classes/container.star", "container")

# toolchain-glibc is the Ubuntu/glibc-side build toolchain. It lives in
# module-ubuntu because it is Ubuntu-side build infrastructure coupled to
# the Ubuntu release pinned in this module's MODULE.star (_UBUNTU_SUITE)
# and the FROM line in this container's Dockerfile.
#
# provides = ["toolchain"] + distro = "debian" wire this into yoe's
# distro-aware toolchain dispatch: classes depend on the virtual name
# "toolchain"; the resolver's provides table finds candidates and the
# per-unit distro compatibility tag narrows to the one matching the
# consuming image's effective distro. Ubuntu images set distro = "debian"
# (the apt/dpkg/glibc backend family), so they resolve "toolchain" to a
# glibc toolchain; Alpine images resolve it to module-alpine's
# toolchain-musl.
#
# CO-LOADING WITH module-debian. Both modules name this unit
# "toolchain-glibc" and tag it distro = "debian". A project that lists
# both modules gets deterministic last-module-wins shadowing on the unit
# name: the toolchain from whichever module is listed later in
# PROJECT.star's `modules` wins. Either glibc toolchain can assemble
# either rootfs — mmdebstrap pulls every target package from the
# project's own repo, and the prebuilt-.deb units only extract data tars
# (no compilation against the toolchain libc) — so the shared name is
# intentional rather than a collision to design around.

container(
    name = "toolchain-glibc",
    version = "1",
    description = "Ubuntu-based build toolchain with glibc, gcc, dpkg-dev, apt-utils, mmdebstrap, and essential build tools",
    provides = ["toolchain"],
    distro = "debian",
)
