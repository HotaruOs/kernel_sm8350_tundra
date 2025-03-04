#!/bin/bash

kernel_dir="${PWD}"
CCACHE=$(command -v ccache)
objdir="${kernel_dir}/out"
anykernel=$HOME/anykernel
builddir="${kernel_dir}/build"
ZIMAGE=$kernel_dir/out/arch/arm64/boot/Image
kernel_name="torracat-tundra"
zip_name="$kernel_name-$(date +"%d%m%Y-%H%M").zip"
TC_DIR=$HOME/tc
CLANG_DIR=$TC_DIR/clang-r522817
export CONFIG_FILE="vendor/tundra-qgki_defconfig"
export ARCH="arm64"
export KBUILD_BUILD_HOST=raghavt20
export KBUILD_BUILD_USER=raghav

export PATH="$CLANG_DIR/bin:$PATH"
if ! [ -d "$TC_DIR" ]; then
    echo "Toolchain not found! Cloning to $TC_DIR..."
    if ! git clone -q --depth=1 --single-branch https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 -b master $TC_DIR; then
        echo "Cloning failed! Aborting..."
        exit 1
    fi
fi

# Colors
NC='\033[0m'
RED='\033[0;31m'
LRD='\033[1;31m'
LGR='\033[1;32m'

make_defconfig() {
    START=$(date +"%s")
    echo -e ${LGR} "########### Generating Defconfig ############${NC}"
    make -s ARCH=${ARCH} O=${objdir} CC=clang HOSTCC=clang ${CONFIG_FILE} LLVM=1 LLVM_IAS=1 -j$(nproc --all)
}

compile() {
    cd ${kernel_dir}
    echo -e ${LGR} "######### Compiling kernel #########${NC}"
    make -j$(nproc --all) \
    O=out \
    ARCH=${ARCH}\
    CC="ccache clang" \
    CLANG_TRIPLE="aarch64-linux-gnu-" \
    CROSS_COMPILE="aarch64-linux-gnu-" \
    CROSS_COMPILE_ARM32="arm-linux-gnueabi-" \
    LLVM=1 \
    LLVM_IAS=1
}

completion() {
    cd ${objdir}
    COMPILED_IMAGE=arch/arm64/boot/Image
    DTB_DIR=arch/arm64/boot/dts/vendor/qcom/
    COMPILED_DTBO=arch/arm64/boot/dts/vendor/qcom/*.img
    COMPILED_DTB=arch/arm64/boot/dts/vendor/qcom/lahaina*dtb
    if [[ -f ${COMPILED_IMAGE} ]]; then

        git clone -q https://github.com/raghavt20/AnyKernel3 -b tundra $anykernel

        cp -f ${COMPILED_IMAGE} $anykernel
        cp -f "${DTB_DIR}"/*.img $anykernel
        mkdir -p $anykernel/dtb
        cp -f "${DTB_DIR}"/lahaina*dtb $anykernel/dtb
        cd $anykernel
        find . -name "*.zip" -type f
        find . -name "*.zip" -type f -delete
        zip -r AnyKernel.zip *
        cp AnyKernel.zip $zip_name
        cp $anykernel/$zip_name $HOME/$zip_name
        rm -rf $anykernel
        END=$(date +"%s")
        DIFF=$(($END - $START))
        curl -F "file=@$HOME/$zip_name" https://temp.sh/upload
        echo -e ${LGR} "############################################"
        echo -e ${LGR} "############# OkThisIsEpic!  ##############"
        echo -e ${LGR} "############################################${NC}"
    else
        echo -e ${RED} "############################################"
        echo -e ${RED} "##         This Is Not Epic :'(           ##"
        echo -e ${RED} "############################################${NC}"
    fi
}

make_defconfig
compile
completion
cd ${kernel_dir}
