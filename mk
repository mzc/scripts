#!/bin/bash

repo=${HOME}/repo
linux=${repo}/linux

if [ ! -d $linux ]
then
	read -p "Linux source code doesn't exist, git clone it from kernel.org? [y/N] " reply

	case $reply in
		y | Y)
			git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git $linux
			;;
		*)
			echo "So, please prepare linux source(in a directory named $linux) by yourself."
			exit 1
			;;
	esac
fi

make -C $linux mrproper
make -C $linux defconfig

${linux}/scripts/config --file ${linux}/.config --enable CONFIG_EXPERIMENTAL
${linux}/scripts/config --file ${linux}/.config --enable CONFIG_DEBUG_INFO
${linux}/scripts/config --file ${linux}/.config --enable CONFIG_KGDB
${linux}/scripts/config --file ${linux}/.config --enable CONFIG_KGDB_SERIAL_CONSOLE
${linux}/scripts/config --file ${linux}/.config --disable CONFIG_DEBUG_RODATA

yes "" | make -C $linux oldconfig

make -C $linux -j$(nproc)
