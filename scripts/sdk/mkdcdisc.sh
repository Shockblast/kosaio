#!/bin/bash
set -e

MKDCDISC_DIR="${DREAMCAST_SDK_EXTRAS}/mkdcdisc"

# Public functions

function info() {
	kosaio_echo "Name: mkdcdisc \n" \
		"Git: https://gitlab.com/simulant/mkdcdisc.git \n" \
		"Description: A tool to create self-booting CDI disc images for the Sega Dreamcast. It simplifies the process of packaging a homebrew project into a burnable image."
}

function clone() {
	__check_requeriments
	kosaio_echo "Cloning mkdcdisc..."
	git clone --depth=1 --single-branch https://gitlab.com/simulant/mkdcdisc.git "${MKDCDISC_DIR}"
	crudini --set "${KOSAIO_CONFIG}" dreamcast_sdk mkdcdisc 1
	kosaio_echo "mkdcdisc has been cloned."
}

function build() {
	__check_requeriments
	__is_installed
	kosaio_echo "Re/Building mkdcdisc..."
	cd "${MKDCDISC_DIR}"
	meson setup builddir
	meson compile -C builddir
	kosaio_echo "mkdcdisc has been built."
}

function update() {
	__check_requeriments
	__is_installed
	kosaio_echo "Checking for mkdcdisc updates..."
	kosaio_git_common_update "${MKDCDISC_DIR}"
	kosaio_echo "mkdcdisc updated"
}

function install() {
	__check_requeriments
	kosaio_echo "Installing mkdcdisc..."
	clone
	build
	install_bin
	kosaio_echo "mkdcdisc installation complete."
}

function install_bin() {
	__check_requeriments
	__is_installed

	if [ ! -f "${MKDCDISC_DIR}/builddir/mkdcdisc" ]; then
		echo "Error: mkdcdisc build not found, build fail?" >&2
		exit 1
	fi

	cp "${MKDCDISC_DIR}/builddir/mkdcdisc" "${DREAMCAST_BIN_PATH}"
}

function uninstall() {
	__is_installed
	kosaio_echo "Uninstalling mkdcdisc..."

	rm -rf "${MKDCDISC_DIR}"

	if [ -f "${DREAMCAST_BIN_PATH}/mkdcdisc" ]; then
		rm -f "${DREAMCAST_BIN_PATH}/mkdcdisc"
	fi

	crudini --set "${KOSAIO_CONFIG}" dreamcast_sdk mkdcdisc 0
	kosaio_echo "mkdcdisc uninstallation complete."
}

# Private functions

function __check_requeriments() {
	kosaio_require_packages git meson build-essential pkg-config libisofs libisofs-dev ninja-build
}

function __is_installed() {
	local IS_INSTALLED=$(crudini --get "${KOSAIO_CONFIG}" dreamcast_sdk mkdcdisc)

	if [ "${IS_INSTALLED}" = "0" ]; then
		kosaio_echo "mkdcdisc is not installled."
		exit 1
	fi

	if [ ! -d "${MKDCDISC_DIR}" ]; then
		kosaio_echo "mkdcdisc folder not found, is mkdcdisc installed?."
		exit 1
	fi
}
