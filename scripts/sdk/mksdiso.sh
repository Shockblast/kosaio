#!/bin/bash
set -e

MKSDISO_DIR="${DREAMCAST_SDK_EXTRAS}/mksdiso"

# Public functions

function info() {
	kosaio_echo "Name: mksdiso \n" \
		"Git: https://github.com/Nold360/mksdiso.git \n" \
		"Description: A tool to create bootable SD card images for ODEs (Optical Drive Emulators) like GDEmu. It allows running homebrew from an SD card instead of a CD-R."
}

function clone() {
	__check_requeriments
	kosaio_echo "Cloning mksdiso..."
	git clone --depth=1 --single-branch https://github.com/Nold360/mksdiso.git "${MKSDISO_DIR}"
	crudini --set "${KOSAIO_CONFIG}" dreamcast_sdk mksdiso 1
	kosaio_echo "mksdiso has been cloned."
}

function build() {
	__check_requeriments
	__is_installed
	kosaio_echo "NOTE: mksdiso can only do install, uninstall and update on this script...\n" \
		"If you want to compile something or explore you will need to open the folder repository here -> (${MKSDISO_DIR})."
}

function update() {
	__check_requeriments
	__is_installed
	kosaio_echo "Checking for mksdiso updates..."
	kosaio_git_common_update "${MKSDISO_DIR}"
	kosaio_echo "mksdiso updated."
}

function install() {
	__check_requeriments
	kosaio_echo "Installing mksdiso..."
	clone
	build
	install_bin
	kosaio_echo "mksdiso installation complete."
}

function install_bin() {
	__check_requeriments
	__is_installed
	cd "${MKSDISO_DIR}"
	make install
	kosaio_echo "mksdiso installed by make."
}

function uninstall() {
	__is_installed
	kosaio_echo "Uninstalling mksdiso..."
	make uninstall
	crudini --set "${KOSAIO_CONFIG}" dreamcast_sdk mksdiso 0
	kosaio_echo "mksdiso uninstallation complete."

}

# Private functions

function __check_requeriments() {
	kosaio_require_packages p7zip wodim genisoimage
}

function __is_installed() {
	local IS_INSTALLED=$(crudini --get "${KOSAIO_CONFIG}" dreamcast_sdk mksdiso)

	if [ "${IS_INSTALLED}" = "0" ]; then
		kosaio_echo "mksdiso is not installled."
		exit 1
	fi

	if [ ! -d "${MKSDISO_DIR}" ]; then
		kosaio_echo "mksdiso folder not found, is mksdiso installed?."
		exit 1
	fi
}
