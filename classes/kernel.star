# Ubuntu kernel meta-package selection, shared by this module's images.
#
# Unlike Debian (linux-image-amd64 / linux-image-arm64), Ubuntu names its
# kernel meta-package by flavour, not arch: linux-image-generic is the
# generic-flavour kernel image meta on every supported architecture. An
# image calls ubuntu_kernel() in its artifact list rather than hardcoding
# the name, so the indirection matches the debian sibling and a future
# flavour split (e.g. a low-latency or cloud kernel) is wired up by
# editing this one map instead of every image.
#
# Both x86_64 and arm64 map to the same name because that is the real
# package name on both. yoe evaluates every image's artifact list up
# front for each arch — even arches that aren't the current build target
# — so ubuntu_kernel() must return cleanly for arm64 too, or an arm64
# build of any sibling image (e.g. an Alpine one) would fail to resolve.
# This module's feed serves amd64 only (see MODULE.star's ARCH SCOPE
# note), so an actual arm64 Ubuntu build fails later at closure
# resolution when linux-image-generic isn't found in the feed — the
# honest failure point, rather than a hardcoded arch error at eval time.

_KERNEL_BY_ARCH = {
    "x86_64": "linux-image-generic",
    "arm64": "linux-image-generic",
}

def ubuntu_kernel():
    """Return the Ubuntu kernel meta-package for the target arch (ctx.arch)."""
    kernel = _KERNEL_BY_ARCH.get(ctx.arch)
    if kernel == None:
        fail("ubuntu_kernel: no kernel package for arch=%s (supported: %s)" %
             (ctx.arch, ", ".join(sorted(_KERNEL_BY_ARCH.keys()))))
    return kernel
