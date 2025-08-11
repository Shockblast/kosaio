#!/bin/bash
set -e

DCLOADIP_DIR="${DREAMCAST_SDK_EXTRAS}/dcload-ip"

# Public functions

function info() {
	kosaio_echo "Name: dcload-ip \n" \
		"Git: https://github.com/KallistiOS/dcload-ip.git \n" \
		"Description: A tool for uploading homebrew applications to the Sega Dreamcast over an IP network. This is essential for rapid development and debugging without burning a new CD for each test."
}

function clone() {
	kosaio_echo "Cloning dcload-ip..."
	git clone --depth=1 --single-branch https://github.com/KallistiOS/dcload-ip.git "${DCLOADIP_DIR}"
	crudini --set "${KOSAIO_CONFIG}" dreamcast_sdk dcload-ip 1
	kosaio_echo "dcload-ip has cloned"
}

function build() {
	__is_installed
	__check_requeriments
	kosaio_echo "Building dcload-ip..."
	cd "${DCLOADIP_DIR}"
	make -j$(nproc)
	kosaio_echo "dcload-ip has build."
}

function update() {
	__is_installed
	__check_requeriments
	kosaio_echo "Checking for dcload-ip updates..."
	kosaio_git_common_update "${DCLOADIP_DIR}"
	kosaio_echo "dcload-ip updated"
}

function install() {
	__check_requeriments
	kosaio_echo "Installing dcload-ip."
	clone
	build
	apply
	kosaio_echo "dcload-ip has been installed."
}

function apply() {
	__is_installed
	__check_requeriments
	cd "${DCLOADIP_DIR}"
	make install
	kosaio_echo "dcload-ip installed by make."
}

function uninstall() {
	__is_installed
	kosaio_echo "Uninstalling dcload-ip."
	rm -rf "${DCLOADIP_DIR}"

	if [ -f "${DREAMCAST_BIN_PATH}/dc-tool-ip" ]; then
		rm -f "${DREAMCAST_BIN_PATH}/dc-tool-ip"
	fi

	crudini --set "${KOSAIO_CONFIG}" dreamcast_sdk dcload-ip 0
	kosaio_echo "dcload-ip has been uninstalled"
}

# Private functions

function __check_requeriments() {
	# Nothing for now
}

function __is_installed() {
	local IS_INSTALLED=$(crudini --get "${KOSAIO_CONFIG}" dreamcast_sdk dcload-ip)

	if [ "${IS_INSTALLED}" = "0" ]; then
		kosaio_echo "dcload-ip is not installled."
		exit 1
	fi

	if [ ! -d "${DCLOADIP_DIR}" ]; then
		kosaio_echo "dcload-ip folder not found, is dcload-ip installed?."
		exit 1
	fi
}
