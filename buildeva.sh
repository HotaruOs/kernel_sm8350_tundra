#!/bin/bash

kernel_dir="${PWD}"
CCACHE=$(command -v ccache)
objdir="${kernel_dir}/out"
anykernel=$HOME/anykernel
builddir="${kernel_dir}/build"
ZIMAGE=$kernel_dir/out/arch/arm64/boot/Image
kernel_name="HuPao"
zip_name="$kernel_name-$(date +"%d%m%Y-%H%M").zip"
GCC_DIR="${PWD}/eva-gcc"
export CONFIG_FILE="vendor/lahaina-qgki_defconfig"
export ARCH="arm64"
export KBUILD_BUILD_HOST=Pão
export KBUILD_BUILD_USER=HotaruOs

if ! [ -d "$GCC_DIR" ]; then
    echo "Eva GCC não encontrado! Baixando..."
    mkdir -p "$GCC_DIR"

    wget -c https://github.com/mvaisakh/gcc-build/releases/download/20072025/eva-gcc-arm64-20072025.xz -O /tmp/eva-gcc-arm64.xz
    wget -c https://github.com/mvaisakh/gcc-build/releases/download/20072025/eva-gcc-arm-20072025.xz -O /tmp/eva-gcc-arm.xz

    if [ $? -ne 0 ]; then
        echo "Erro: Falha no download do Eva GCC."
        exit 1
    fi

    tar -xf /tmp/eva-gcc-arm64.xz -C "$GCC_DIR"
    tar -xf /tmp/eva-gcc-arm.xz -C "$GCC_DIR"

    if [ $? -ne 0 ]; then
        echo "Erro: Falha ao extrair o Eva GCC."
        exit 1
    fi

    echo "Eva GCC instalado com sucesso em $GCC_DIR."
else
    echo "Eva GCC já está instalado em $GCC_DIR."
fi

# Colors
NC='\033[0m'
RED='\033[0;31m'
LRD='\033[1;31m'
LGR='\033[1;32m'

GCC_ARM64="$GCC_DIR/gcc-arm64"
GCC_ARM32="$GCC_DIR/gcc-arm"

PATH=$GCC_ARM64/bin/:$GCC_ARM32/bin/:/usr/bin:$PATH
C_PATH=$GCC_ARM64/bin/:$GCC_ARM32

echo -e "${LGR}######### Versão do GCC #########${NC}"
echo "Versão do GCC ARM64: $($GCC_ARM64/bin/aarch64-elf-gcc --version)"

make_defconfig() {
    echo -e ${LGR} "########### Gerando Defconfig ############${NC}"
    make -s ARCH=${ARCH} O=${objdir} ${CONFIG_FILE} -j$(nproc --all)
}

compile() {
    cd ${kernel_dir}
    echo -e ${LGR} "######### Compilando Kernel #########${NC}"
    make -j$(nproc --all) \
    O=out \
    ARCH=${ARCH} \
    CC="gcc" \
    CROSS_COMPILE="$GCC_ARM64/bin/aarch64-elf-" \
    CROSS_COMPILE_COMPAT="$GCC_ARM32/bin/arm-eabi-" \
    CC_COMPAT=arm-eabi-gcc \
    AR=aarch64-elf-ar \
    OBJDUMP=aarch64-elf-objdump \
    STRIP=aarch64-elf-strip
}

completion() {
    cd ${objdir}
    COMPILED_IMAGE=arch/arm64/boot/Image
    DTB_DIR=arch/arm64/boot/dts/vendor/qcom/
    COMPILED_DTBO=arch/arm64/boot/dts/vendor/qcom/*.img
    COMPILED_DTB=arch/arm64/boot/dts/vendor/qcom/lahaina*dtb
    if [[ -f ${COMPILED_IMAGE} ]]; then

        git clone -q https://github.com/HotaruOs/AnyKernel3 -b pão $anykernel

        cp -f ${COMPILED_IMAGE} $anykernel
        cp -f "${DTB_DIR}"/*.img $anykernel
        mkdir -p $anykernel/dtb
        cp -f "${DTB_DIR}"/lahaina*dtb $anykernel/dtb
        cd $anykernel
        find . -name "*.zip" -type f
        find . -name "*.zip" -type f -delete
        zip -r AnyKernel.zip *
        cp AnyKernel.zip $zip_name
        cp $anykernel/$zip_name $kernel_dir/$zip_name
        rm -rf $anykernel
        END=$(date +"%s")
        DIFF=$(($END - $START))
        curl -F "file=@$kernel_dir/$zip_name" https://temp.sh/upload
	echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
        echo -e ${LGR} "#############################################"
        echo -e ${LGR} "####### Kernel compiled successfully ########"
        echo -e ${LGR} "#############################################${NC}"
    else
        echo -e ${RED} "#############################################"
        echo -e ${RED} "######## Failed to compile Kernel #########"
        echo -e ${RED} "#############################################${NC}"
    fi
}

make_defconfig
compile
completion
cd ${kernel_dir}
