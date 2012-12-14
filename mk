#!/bin/bash

source utils.lib

function is_source_exist {
    local readme=$linux/README

    if [ ! -d $linux -o ! -e $readme ]; then
	die "$linux: Cannot find linux souce."
    fi

    local res=$(head -n 1 "$readme" | grep "Linux kernel")
    if [ -z "$res" ]; then
	die "$linux: Cannot find linux souce."
    fi
}

function config_for_kvm {
    make -C $linux mrproper
    make -C $linux defconfig

    $linux/scripts/config --file $linux/.config --enable CONFIG_EXPERIMENTAL
    $linux/scripts/config --file $linux/.config --enable CONFIG_DEBUG_INFO
    $linux/scripts/config --file $linux/.config --enable CONFIG_KGDB
    $linux/scripts/config --file $linux/.config --enable CONFIG_KGDB_SERIAL_CONSOLE
    $linux/scripts/config --file $linux/.config --disable CONFIG_DEBUG_RODATA

    yes "" | make -C $linux oldconfig
}

function config_for_stp {
    make -C $linux mrproper
    make -C $linux localmodconfig

    $linux/scripts/config --file $linux/.config --set-str CONFIG_LOCALVERSION "-mzc"
    $linux/scripts/config --file $linux/.config --enable CONFIG_DEBUG_INFO
    $linux/scripts/config --file $linux/.config --enable CONFIG_KPROBES
    $linux/scripts/config --file $linux/.config --enable CONFIG_RELAY
    $linux/scripts/config --file $linux/.config --enable CONFIG_DEBUG_FS
    $linux/scripts/config --file $linux/.config --enable CONFIG_MODULES
    $linux/scripts/config --file $linux/.config --enable CONFIG_MODULE_UNLOAD
    $linux/scripts/config --file $linux/.config --enable CONFIG_UTRACE

    yes "" | make -C $linux oldconfig
}

function compile_kernel {
    make -C $linux -j$(nproc)
}

function build_cscope {
    make -C $linux cscope
}

function is_kernel_compiled {
    if [ ! -e $vmlinuz ]; then
	die "Kernel has not been compiled."
    fi
}

function get_kernel_version {
    local kernel_release=$linux/include/config/kernel.release
    kernel_version=$(cat $kernel_release)
}

function is_kernel_installed {
    local lib_modules=/lib/modules/$kernel_version
    if [ -d $lib_modules ]; then
	die "Kernel: $kernel_version has already installed."
    fi
}

function install_kernel_on_ubuntu {
    sudo make -C $linux modules_install

    local vmlinuz_target=/boot/vmlinuz-$kernel_version
    local system_map_target=/boot/System.map-$kernel_version
    local config_target=/boot/config-$kernel_version
    local initrd_target=/boot/initd.img-$kernel_version

    sudo cp -v $vmlinuz $vmlinuz_target
    sudo cp -v $system_map $system_map_target
    sudo cp -v $config $config_target
    sudo mkinitramfs -k -o $initrd_target $kernel_version

    sudo update-grub2
}

function install_kernel_on_arch {
    sudo make -C $linux modules_install

    local vmlinuz_target=/boot/vmlinuz-mzc
    local initrd_target=/boot/initramfs-mzc.img

    sudo cp -v $vmlinuz $vmlinuz_target
    sudo mkinitcpio -k $kernel_versoin -g $initrd_target
}

function get_distributor {
    echo "ubuntu"
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
	if [ "$dist" = "ubuntu" ]; then
	    install_kernel_on_ubuntu
	elif [ "$dist" = "arch" ]; then
	    install_kernel_on_arch
	fi
    fi

    exit 0
}

args=$(getopt -o "ksi" -l "kvm,stp,install" -n "getopt.sh" -- "$@")
if [ $? -ne 0 ]; then
    exit 1
fi

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
