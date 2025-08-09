#!/bin/bash
set -e

MAKEIP_DIR="${DREAMCAST_SDK_EXTRAS}/makeip"

# Public functions

function info() {
	kosaio_echo "Name: makeip \n" \
		"Git: https://github.com/Dreamcast-Projects/makeip.git \n" \
		"Description: A tool to create IP.BIN boot files for Sega Dreamcast executables. This file contains metadata like the game title and is required for booting. \n" \
		"Note: This version is more up-to-date than the one integrated in Kallistios."
}

function clone() {
	__check_requeriments
	kosaio_echo "Cloning makeip."
	git clone --depth=1 --single-branch "https://github.com/Dreamcast-Projects/makeip.git" "${MAKEIP_DIR}"
	crudini --set "${KOSAIO_CONFIG}" dreamcast_sdk makeip 1
	kosaio_echo "makeip has been cloned."
}

function build() {
	__check_requeriments
	__is_installed
	kosaio_echo "Re/Building makeip..."
	cd "${MAKEIP_DIR}/src"
	make -j$(nproc)
	kosaio_echo "makeip has been built."
}

function update() {
	__check_requeriments
	__is_installed
	kosaio_echo "Checking for makeip updates..."
	kosaio_git_common_update "${MAKEIP_DIR}"
	kosaio_echo "makeip updated"
}

function install() {
	__check_requeriments
	kosaio_echo "Installing makeip..."
	clone
	build
	install_bin
	kosaio_echo "makeip installation complete."
}

function install_bin() {
	__check_requeriments
	__is_installed
	cd "${MAKEIP_DIR}/src"
	make install
	kosaio_echo "makeip installed by make."
}

function uninstall() {
	__is_installed
	kosaio_echo "Uninstalling makeip..."
	rm -rf "${MAKEIP_DIR}"

	if [ -d "${DREAMCAST_BIN_PATH}/makeip" ]; then
		rm -f "${DREAMCAST_BIN_PATH}/makeip"
	fi

	crudini --set "${KOSAIO_CONFIG}" dreamcast_sdk makeip 0
	kosaio_echo "makeip uninstallation complete."
}

# Private functions

function __check_requeriments() {
	kosaio_require_packages libpng-dev
}

function __is_installed() {
	local IS_INSTALLED=$(crudini --get "${KOSAIO_CONFIG}" dreamcast_sdk makeip)

	if [ "${IS_INSTALLED}" = "0" ]; then
		kosaio_echo "makeip is not installled."
		exit 1
	fi

	if [ ! -d "${MAKEIP_DIR}" ]; then
		kosaio_echo "makeip folder not found, is makeip installed?."
		exit 1
	fi
}
