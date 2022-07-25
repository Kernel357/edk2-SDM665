#!/bin/bash
# based on the instructions from edk2-platform
set -e
. build_common.sh

rm -rf Build/sdm665/DEBUG_GCC5/FV/Ffs/7E374E25-8E01-4FEE-87F2-390C23C606CDFVMAIN
# not actually GCC5; it's GCC7 on Ubuntu 18.04.
GCC5_AARCH64_PREFIX=aarch64-linux-gnu- build -s -n 0 -a AARCH64 -t GCC5 -p sdm665Pkg/sdm665Pkg.dsc -b DEBUG
gzip -c < /home/kernel/UEFI/edk2-ginkgo/edk2-sdm665/Build/sdm665Pkg/DEBUG_GCC5/FV/SDM665PKG_UEFI.fd >uefi_image
cat laurel_sprout.dtb >>uefi_image

abootimg --create uefi.img -k uefi_image -r ramdisk  -f bootimg.cfg
