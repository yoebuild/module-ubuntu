load("@core//classes/image.star", "image")
load("//classes/kernel.star", "ubuntu_kernel")

# Minimal bootable Ubuntu image. The artifact set is the smallest
# closure that boots in QEMU and accepts an SSH login: kernel, init
# system (systemd via systemd-sysv), libc6, coreutils, bash, dpkg/apt,
# openssh-server, and a connection manager. Expand per project as the
# device's runtime requirements grow; the Debian sibling is
# module-debian's base-image.
#
# distro = "ubuntu" is its own distro in yoe's resolver (so Ubuntu and
# Debian images don't collide), but it rides the shared apt/dpkg/glibc
# backend — the same mmdebstrap rootfs-assembly and toolchain path Debian
# uses. yoe treats "debian" and "ubuntu" as one apt family for assembly
# while keeping their feeds, suites, and closures distinct.
#
# The rootfs is assembled with `mmdebstrap --variant=custom`, which
# installs exactly this closure and its hard dependencies — no implicit
# Essential/Priority base. That keeps the image minimal but means the
# packages dpkg itself needs at configure time must be listed
# explicitly: dash (/bin/sh for maintainer scripts), diffutils (diff
# for conffile handling), libc-bin (ldconfig), and the base-files /
# base-passwd that seed /etc. Without them mmdebstrap aborts with
# "expected programs not found in PATH".
image(
    name = "base-image",
    distro = "ubuntu",
    artifacts = [
        ubuntu_kernel(),
        "systemd-sysv",
        "systemd-resolved",
        "init",
        "libc6",
        # dpkg/boot essentials the custom variant won't pull implicitly
        "libc-bin",
        "base-files",
        "base-passwd",
        "dash",
        "diffutils",
        "coreutils",
        "bash",
        "dpkg",
        "apt",
        "openssh-server",
        # NetworkManager: connection manager for Ubuntu device images.
        # Self-enables via postinst and auto-DHCPs unmanaged ethernet,
        # so the wired NIC comes up with no profile — matching the
        # Debian sibling's networking choice.
        "network-manager",
    ],
)
