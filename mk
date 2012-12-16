#!/bin/bash

source utils.lib

function is_source_exist {
    local readme="${linux}/README"
    [ -d "${linux}" -a -e "${readme}" ] || die "${linux}: Cannot find linux souce."

    local res=$(head -n 1 "${readme}" | grep "Linux kernel")
    [ "${res}" ] || die "${linux}: Cannot find linux souce."
}

function config_for_kvm {
    make -C "${linux}" mrproper
    make -C "${linux}" defconfig

    ${config_cmd} --file "${config}" --enable CONFIG_EXPERIMENTAL
    ${config_cmd} --file "${config}" --enable CONFIG_DEBUG_INFO
    ${config_cmd} --file "${config}" --enable CONFIG_KGDB
    ${config_cmd} --file "${config}" --enable CONFIG_KGDB_SERIAL_CONSOLE
    ${config_cmd} --file "${config}" --disable CONFIG_DEBUG_RODATA

    yes "" | make -C "${linux}" oldconfig
}

function config_for_stp {
    make -C "${linux}" mrproper
    make -C "${linux}" localmodconfig

    ${config_cmd} --file "${config}" --set-str CONFIG_LOCALVERSION "-mzc"
    ${config_cmd} --file "${config}" --enable CONFIG_DEBUG_INFO
    ${config_cmd} --file "${config}" --enable CONFIG_KPROBES
    ${config_cmd} --file "${config}" --enable CONFIG_RELAY
    ${config_cmd} --file "${config}" --enable CONFIG_DEBUG_FS
    ${config_cmd} --file "${config}" --enable CONFIG_MODULES
    ${config_cmd} --file "${config}" --enable CONFIG_MODULE_UNLOAD
    ${config_cmd} --file "${config}" --enable CONFIG_UTRACE

    yes "" | make -C "${linux}" oldconfig
}

function compile_kernel {
    make -C "${linux}" -j$(nproc)
}

function build_cscope {
    make -C "${linux}" cscope
}

function is_kernel_compiled {
    [ -e "${vmlinuz}" ] || die "Kernel has not been compiled."
}

function get_kernel_version {
    kernel_version=$(cat "${linux}/include/config/kernel.release")
}

function is_kernel_installed {
    [ ! -d "/lib/modules/${kernel_version}" ] || die "Kernel: ${kernel_version} has already installed."
}

function install_kernel_on_ubuntu {
    sudo make -C "${linux}" modules_install

    sudo cp -v "${vmlinuz}" "/boot/vmlinuz-${kernel_version}"
    sudo cp -v "${system_map}" "/boot/System.map-${kernel_version}"
    sudo cp -v "${config}" "/boot/config-${kernel_version}"

    local initrd="/boot/initd.img-${kernel_version}"
    sudo mkinitramfs -k -o "${initrd}" "${kernel_version}"

    sudo update-grub2
}

function install_kernel_on_arch {
    sudo make -C "${linux}" modules_install

    sudo cp -v "${vmlinuz}" "/boot/vmlinuz-${kernel_version}"

    local initramfs="/boot/initramfs-${kernel_version}.img"
    sudo mkinitcpio -k "${kernel_version}" -g "${initramfs}"

    sudo grub-mkconfig -o /boot/grub/grub.cfg
}

function get_distributor {
    echo $(lsb_release --id | awk '{ print $3 }')
}

function main {
    init

    is_source_exist

    if [ "$kvm" = "yes" ]; then
	config_for_kvm
    elif [ "$stp" = "yes" ]; then
	config_for_stp
    fi

    if [ "$kvm" = "yes" -o "$stp" = "yes" ]; then
	compile_kernel
    	build_cscope
    fi

    if [ "$install" = "yes" ]; then
	is_kernel_compiled
	get_kernel_version
	is_kernel_installed
	
	local dist=$(get_distributor)
	if [ "$dist" = "Ubuntu" ]; then
	    install_kernel_on_ubuntu
	elif [ "$dist" = "arch" ]; then
	    install_kernel_on_arch
	fi
    fi

    exit 0
}

args=$(getopt -o "ksi" -l "kvm,stp,install" -n "getopt.sh" -- "$@")
[ $? -eq 0 ] || exit 1

eval set -- "$args"

kvm=no
stp=no
linux=$(pwd)
install=no
while true; do
    case "$1" in
	-k|--kvm)
	    kvm=yes
	    shift;;
	-s|--stp)
	    stp=yes
	    shift;;
	-i|--install)
	    install=yes
	    shift;;
	--)
	    shift
	    break;;
    esac
done

main
