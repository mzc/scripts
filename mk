#!/bin/bash

source utils.lib

function get_linux {
    git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git $linux
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

    ${linux}/scripts/config --file ${linux}/.config --enable CONFIG_KPROBES
    ${linux}/scripts/config --file ${linux}/.config --disable CONFIG_KPROBES_SANITY_TEST
    ${linux}/scripts/config --file ${linux}/.config --enable CONFIG_KPROBE_EVENT

    ${linux}/scripts/config --file ${linux}/.config --module CONFIG_NET_DCCPPROBE
    ${linux}/scripts/config --file ${linux}/.config --module CONFIG_NET_SCTPPROBE
    ${linux}/scripts/config --file ${linux}/.config --enable CONFIG_NET_TCPPROBE

    ${linux}/scripts/config --file ${linux}/.config --enable CONFIG_DEBUG_FS
    ${linux}/scripts/config --file ${linux}/.config --enable CONFIG_DEBUG_INFO
    ${linux}/scripts/config --file ${linux}/.config --disable CONFIG_DEBUG_INFO_REDUCED

    ${linux}/scripts/config --file ${linux}/.config --enable CONFIG_UTRACE
    ${linux}/scripts/config --file ${linux}/.config --enable CONFIG_RELAY
    ${linux}/scripts/config --file ${linux}/.config --disable CONFIG_X86_DECODER_SELFTEST
    ${linux}/scripts/config --file ${linux}/.config --enable CONFIG_MODULES
    ${linux}/scripts/config --file ${linux}/.config --enable CONFIG_MODULE_UNLOAD

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
    if [ ! -d $linux ]; then
	get_linux
    fi

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
