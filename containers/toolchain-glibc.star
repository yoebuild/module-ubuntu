load("@core//classes/container.star", "container")

# toolchain-glibc is the Ubuntu/glibc-side build toolchain. It lives in
# module-ubuntu because it is Ubuntu-side build infrastructure coupled to
# the Ubuntu release pinned in this module's MODULE.star (_UBUNTU_SUITE)
# and the FROM line in this container's Dockerfile.
#
# provides = ["toolchain"] + distro = "ubuntu" wire this into yoe's
# distro-aware toolchain dispatch: classes depend on the virtual name
# "toolchain"; the resolver's provides table finds candidates and the
# per-unit distro tag narrows to the one matching the consuming image's
# effective distro. Ubuntu images (distro = "ubuntu") resolve "toolchain"
# to this container; Debian images resolve it to module-debian's
# toolchain-glibc; Alpine images resolve it to module-alpine's
# toolchain-musl.
#
# CO-LOADING WITH module-debian. Both modules name this unit
# "toolchain-glibc", but tag it with their own distro ("ubuntu" here,
# "debian" there). yoe's per-distro resolver view keeps the two separate:
# an Ubuntu closure sees only this one, a Debian closure only the other,
# so they coexist in one project without colliding — the same way each
# distro's base-image does.

container(
    name = "toolchain-glibc",
    version = "1",
    description = "Ubuntu-based build toolchain with glibc, gcc, dpkg-dev, apt-utils, mmdebstrap, and essential build tools",
    provides = ["toolchain"],
    distro = "ubuntu",
)
