#!/bin/bash

function init {
    repo=${HOME}/repo
    linux=${repo}/linux
}

function get_linux {
    git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git $linux
}

function config_linux {
    make -C $linux mrproper
    make -C $linux defconfig

    ${linux}/scripts/config --file ${linux}/.config --enable CONFIG_EXPERIMENTAL
    ${linux}/scripts/config --file ${linux}/.config --enable CONFIG_DEBUG_INFO
    ${linux}/scripts/config --file ${linux}/.config --enable CONFIG_KGDB
    ${linux}/scripts/config --file ${linux}/.config --enable CONFIG_KGDB_SERIAL_CONSOLE
    ${linux}/scripts/config --file ${linux}/.config --disable CONFIG_DEBUG_RODATA

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
	config_linux
	compile_linux
	build_cscope
    elif [ $all = "yes" ]; then
	config_linux
	compile_linux
	build_cscope
    else
	compile_linux	
    fi
    exit 0
}

ARGS=$(getopt -o "a" -l "all" -n "getopt.sh" -- "$@")
if [ $? -ne 0 ]; then
    exit 1
fi

eval set -- "$ARGS"

all=no
while true; do
    case "$1" in
	-a|--all)
	    all=yes
	    shift;;
	--)
	    shift
	    break;;
    esac
done

main
