#!/bin/bash
set -e

DCLOADSERIAL_DIR="${DREAMCAST_SDK_EXTRAS}/dcload-serial"

# Public functions

function info() {
	kosaio_echo "Name: dcload-serial \n" \
		"Git: https://github.com/KallistiOS/dcload-serial.git \n" \
		"Description: A tool for uploading homebrew applications to the Sega Dreamcast over a serial connection. This is an alternative to dcload-ip, useful for developers using a serial cable for communication."
}

function clone() {
	kosaio_echo "Cloning dcload-serial..."
	git clone --depth=1 --single-branch https://github.com/KallistiOS/dcload-serial.git "${DCLOADSERIAL_DIR}"
	crudini --set "${KOSAIO_CONFIG}" dreamcast_sdk dcload-serial 1
	kosaio_echo "dcload-serial has cloned"
}

function build() {
	__is_installed
	__check_requeriments
	kosaio_echo "Building dcload-serial..."
	cd "${DCLOADSERIAL_DIR}"
	make -j$(nproc)
	kosaio_echo "dcload-serial has build."
}

function update() {
	__is_installed
	__check_requeriments
	kosaio_echo "Checking for dcload-serial updates..."
	kosaio_git_common_update "${DCLOADSERIAL_DIR}"
	kosaio_echo "dcload-serial updated"
}

function install() {
	__check_requeriments
	kosaio_echo "Installing dcload-serial."
	clone
	build
	apply
	kosaio_echo "dcload-serial has been installed"
}

function apply() {
	__is_installed
	__check_requeriments
	cd "${DCLOADSERIAL_DIR}"
	make install
	kosaio_echo "dcload-serial installed by make."
}

function uninstall() {
	__is_installed
	kosaio_echo "Uninstalling dcload-serial."
	rm -rf "${DCLOADSERIAL_DIR}"

	if [ -f "${DREAMCAST_BIN_PATH}/dc-tool-serial" ]; then
		rm -f "${DREAMCAST_BIN_PATH}/dc-tool-serial"
	fi

	crudini --set "${KOSAIO_CONFIG}" dreamcast_sdk dcload-serial 0
	kosaio_echo "dcload-serial has been uninstalled"
}

# Private functions

function __check_requeriments() {
	# Nothing for now
}

function __is_installed() {
	local IS_INSTALLED=$(crudini --get "${KOSAIO_CONFIG}" dreamcast_sdk dcload-serial)

	if [ "${IS_INSTALLED}" = "0" ]; then
		kosaio_echo "dcload-serial is not installled."
		exit 1
	fi

	if [ ! -d "${DCLOADSERIAL_DIR}" ]; then
		kosaio_echo "dcload-serial folder not found, is dcload-serial installed?."
		exit 1
	fi
}
