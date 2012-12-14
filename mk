#!/bin/bash

source utils.lib

function check_linux_source {
    readme=${linux}/README

    if [ ! -d $linux -o ! -e $readme ]; then
	die "$linux: Cannot find linux souce."
    fi

    res=$(head -n 1 $readme | grep "Linux kernel")
    if [ -z "$res" ]; then
	die "$linux: Cannot find linux souce."
    fi
}

function config_linux_kvm {
    make -C $linux mrproper
    make -C $linux defconfig

    ${linux}/scripts/config --file ${linux}/.config --enable CONFIG_EXPERIMENTAL
    ${linux}/scripts/config --file ${linux}/.config --enable CONFIG_DEBUG_INFO
    ${linux}/scripts/config --file ${linux}/.config --enable CONFIG_KGDB
    ${linux}/scripts/config --file ${linux}/.config --enable CONFIG_KGDB_SERIAL_CONSOLE
    ${linux}/scripts/config --file ${linux}/.config --disable CONFIG_DEBUG_RODATA

    yes "" | make -C $linux oldconfig
}

function config_linux_stp {
    make -C $linux mrproper
    make -C $linux localmodconfig

    ${linux}/scripts/config --file ${linux}/.config --set-str CONFIG_LOCALVERSION "-mzc"

    ${linux}/scripts/config --file ${linux}/.config --enable CONFIG_DEBUG_INFO
    ${linux}/scripts/config --file ${linux}/.config --enable CONFIG_KPROBES
    ${linux}/scripts/config --file ${linux}/.config --enable CONFIG_RELAY
    ${linux}/scripts/config --file ${linux}/.config --enable CONFIG_DEBUG_FS
    ${linux}/scripts/config --file ${linux}/.config --enable CONFIG_MODULES
    ${linux}/scripts/config --file ${linux}/.config --enable CONFIG_MODULE_UNLOAD
    ${linux}/scripts/config --file ${linux}/.config --enable CONFIG_UTRACE

    yes "" | make -C $linux oldconfig
}

function compile_linux {
    make -C $linux -j$(nproc)
}

function build_cscope {
    make -C $linux cscope
}

function main {
    init

    check_linux_source

    if [ $kvm = "yes" ]; then
	config_linux_kvm
    elif [ $stp = "yes" ]; then
	config_linux_stp
    fi

    compile_linux
    
    if [ $kvm = "yes" -o $stp = "yes" ]; then
	build_cscope
    fi

    exit 0
}

args=$(getopt -o "ks" -l "kvm,stp" -n "getopt.sh" -- "$@")
if [ $? -ne 0 ]; then
    exit 1
fi

eval set -- "$args"

kvm=no
stp=no
linux=$(pwd)
while true; do
    case "$1" in
	-k|--kvm)
	    kvm=yes
	    shift;;
	-s|--stp)
	    stp=yes
	    shift;;
	--)
	    shift
	    break;;
    esac
done

main
