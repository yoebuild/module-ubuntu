load("@core//classes/image.star", "image")
load("//classes/kernel.star", "ubuntu_kernel")

# Ubuntu dev-image: the base-image closure plus a diagnostic and
# editor userland so the device is usable for actual work over SSH.
# Mirrors the spirit of module-alpine's and module-debian's dev-images
# (htop, strace, less, file, curl, etc.) using Ubuntu's apt-side
# equivalents.
#
# distro = "ubuntu" selects yoe's apt/dpkg/glibc backend (the package-
# format family, not the upstream archive).
image(
    name = "dev-image",
    distro = "ubuntu",
    artifacts = [
        # base-image closure
        ubuntu_kernel(),
        "systemd-sysv",
        "systemd-resolved",
        "init",
        "libc6",
        # dpkg/boot essentials the custom variant won't pull implicitly
        # (dash=/bin/sh, diffutils=diff, libc-bin=ldconfig, base-*=/etc)
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
        # network-manager + the drop-in that makes NM manage (auto-DHCP)
        # the wired QEMU NIC on Ubuntu; see base-image for the rationale.
        "network-manager",
        "nm-manage-ethernet",
        # dev additions
        "ca-certificates",
        "curl",
        "less",
        "file",
        "htop",
        "strace",
        "procps",
        "iproute2",
        "iputils-ping",
        "vim-tiny",
    ],
)
