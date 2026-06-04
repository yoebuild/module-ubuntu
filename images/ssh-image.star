load("@core//classes/image.star", "image")
load("//classes/kernel.star", "ubuntu_kernel")

# Minimal Ubuntu image that boots and accepts an SSH login, carrying no
# extra developer tooling — the Ubuntu counterpart to module-alpine's
# ssh-image, for an apples-to-apples size comparison across distros.
# This is the same closure as this module's base-image (already the
# smallest boot + SSH set): kernel, systemd init, libc, coreutils, bash,
# dpkg/apt, openssh-server, and NetworkManager for DHCP.
#
# distro = "ubuntu" selects yoe's apt/dpkg/glibc backend (the package-
# format family, not the upstream archive). The custom mmdebstrap variant
# installs exactly this closure and its hard dependencies, so the
# dpkg-configure essentials (dash, diffutils, libc-bin, base-files,
# base-passwd) are listed explicitly — see the base-image comment for why
# each is required.
image(
    name = "ssh-image",
    distro = "ubuntu",
    artifacts = [
        ubuntu_kernel(),
        "systemd-sysv",
        "systemd-resolved",
        "init",
        "libc6",
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
        # network-manager + the drop-in that makes NM manage wired ethernet
        # on Ubuntu (see base-image for why the drop-in is needed).
        "network-manager",
        "nm-manage-ethernet",
    ],
)
