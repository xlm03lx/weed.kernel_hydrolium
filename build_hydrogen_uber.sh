#!/bin/bash

# Custom build script for foe.kernel

# Constants
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
cyan='\033[0;36m'
yellow='\033[0;33m'
blue='\033[0;34m'
default='\033[0m'

# Define variables
KERNEL_DIR=$PWD
Anykernel_DIR=$KERNEL_DIR/AnyKernel2/
DATE=$(date +"%d%m%Y")
TIME=$(date +"-%H.%M.%S")
KERNEL_NAME="weed.kernel"
DEVICE="-hydrogen-UBER-"
FINAL_ZIP="$KERNEL_NAME""$DEVICE""$DATE""$TIME"

BUILD_START=$(date +"%s")

# Cleanup before
rm -rf $Anykernel_DIR/*zip
rm -rf $Anykernel_DIR/Image.gz-dtb
rm -rf arch/arm64/boot/Image
rm -rf arch/arm64/boot/dts/qcom/hydrogen-msm8956-mtp.dtb
rm -rf arch/arm64/boot/dts/qcom/hydrogen-msm8976-mtp.dtb
rm -rf arch/arm64/boot/dts/qcom/hydrogen-msm8956-v1.1-mtp.dtb
rm -rf arch/arm64/boot/dts/qcom/hydrogen-msm8976-v1.1-mtp.dtb
rm -rf arch/arm64/boot/Image.gz
rm -rf arch/arm64/boot/Image.gz-dtb

# Export few variables
export KBUILD_BUILD_USER="rokok"
export KBUILD_BUILD_HOST="daun"
export CROSS_COMPILE=/home/xfoex/kernel5/aarch64-linux-android-4.9-uber-master/bin/aarch64-linux-android-
export ARCH="arm64"
export USE_CCACHE=1

echo -e "$green***********************************************"
echo  "           Compiling weed.kernel HYDROGEN                   "
echo -e "***********************************************"

# Finally build it
make clean && make mrproper
make lineageos_hydrogen_defconfig
make -j5

echo -e "$yellow***********************************************"
echo  "                 Zipping up                    "
echo -e "***********************************************"

# Create the flashable zip
cp arch/arm64/boot/Image.gz-dtb $Anykernel_DIR
cd $Anykernel_DIR
zip -r9 $FINAL_ZIP.zip * -x .git README.md *placeholder

echo -e "$cyan***********************************************"
echo  "            Cleaning up the mess created               "
echo -e "***********************************************$default"

# Cleanup again
cd ../
rm -rf $Anykernel_DIR/Image.gz-dtb
rm -rf arch/arm64/boot/Image
rm -rf arch/arm64/boot/dts/qcom/hydrogen-msm8956-mtp.dtb
rm -rf arch/arm64/boot/dts/qcom/hydrogen-msm8976-mtp.dtb
rm -rf arch/arm64/boot/dts/qcom/hydrogen-msm8956-v1.1-mtp.dtb
rm -rf arch/arm64/boot/dts/qcom/hydrogen-msm8976-v1.1-mtp.dtb
rm -rf arch/arm64/boot/Image.gz
rm -rf arch/arm64/boot/Image.gz-dtb
make clean && make mrproper

# Build complete
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$green Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$default"
