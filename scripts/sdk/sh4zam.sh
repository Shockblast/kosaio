#!/bin/bash
set -e

SH4ZAM_DIR="${DREAMCAST_SDK_EXTRAS}/sh4zam"

# Public functions

function info() {
	kosaio_echo "Name: sh4zam \n" \
		"Git: https://github.com/gyrovorbis/sh4zam.git \n" \
		"Description: A hand-optimized, general-purpose math and linear algebra library for harnessing the floating-point power of the SH4 processor in the Sega Dreamcast. \n" \
		"Note: Kos is required to use sh4zam"
}

function clone() {
	kosaio_echo "Cloning sh4zam..."
	git clone --depth=1 --single-branch https://github.com/gyrovorbis/sh4zam.git "${SH4ZAM_DIR}"
	crudini --set "${KOSAIO_CONFIG}" dreamcast_sdk sh4zam 1
	kosaio_echo "sh4zam has been cloned."
}

function build() {
	__is_installed
	__check_requeriments
	kosaio_echo "Re/Building sh4zam..."
	cd "${SH4ZAM_DIR}"

	if [ -d "build" ]; then
		rm -rf build
	fi

	mkdir -p build
	cd build
	kos-cmake ..
	make -j$(nproc)
	kosaio_echo "sh4zam has been built."
}

function update() {
	__is_installed
	__check_requeriments
	kosaio_echo "Checking for sh4zam updates..."
	kosaio_git_common_update "${SH4ZAM_DIR}"
	kosaio_echo "sh4zam updated."
}

function install() {
	__check_requeriments
	kosaio_echo "Installing sh4zam..."
	clone
	build
	apply
	kosaio_echo "sh4zam installation complete."
}

function apply() {
	__is_installed
	__check_requeriments
	cd "${SH4ZAM_DIR}/build"
	make install
	kosaio_echo "sh4zam installed by make..."
}

function uninstall() {
	__is_installed
	kosaio_echo "Uninstalling sh4zam..."
	cd "${SH4ZAM_DIR}"
	make -f Makefile.kos uninstall
	cd ..
	rm -rf "${SH4ZAM_DIR}"
	crudini --set "${KOSAIO_CONFIG}" dreamcast_sdk sh4zam 0
	kosaio_echo "Sh4zam uninstallation complete."
}

# Private functions

function __check_requeriments() {
	local IS_INSTALLED=$(crudini --get "${KOSAIO_CONFIG}" dreamcast_sdk kos)

	if [ "${IS_INSTALLED}" = "0" ]; then
		kosaio_echo "KOS is required to compile/use Sh4zam."
		exit 1
	fi
}

function __is_installed() {
	local IS_INSTALLED=$(crudini --get "${KOSAIO_CONFIG}" dreamcast_sdk sh4zam)

	if [ "${IS_INSTALLED}" = "0" ]; then
		kosaio_echo "Sh4zam is not installled."
		exit 1
	fi

	if [ ! -d "${SH4ZAM_DIR}" ]; then
		kosaio_echo "Sh4zam folder not found, is Sh4zam installed?."
		exit 1
	fi
}
