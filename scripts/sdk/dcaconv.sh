#!/bin/bash
set -e

DCACONV_DIR="${DREAMCAST_SDK_EXTRAS}/dcaconv"

# Public functions

function info() {
	kosaio_echo "Name: dcaconv \n" \
		"Git: https://github.com/TapamN/dcaconv.git \n" \
		"Description: dcaconv converts audio to a format for the Dreamcast's AICA."
}

function clone() {
	kosaio_echo "Cloning dcaconv..."
	git clone --depth=1 --single-branch https://github.com/TapamN/dcaconv.git "${DCACONV_DIR}"
	crudini --set "${KOSAIO_CONFIG}" dreamcast_sdk dcaconv 1
	kosaio_echo "dcaconv has cloned."
}

function build() {
	__is_installed
	__check_requeriments
	kosaio_echo "Building dcaconv..."
	cd "${DCACONV_DIR}"
	make -j$(nproc)
	kosaio_echo "dcaconv has build."
}

function update() {
	__is_installed
	__check_requeriments
	kosaio_echo "Checking for dcaconv updates..."
	kosaio_git_common_update "${DCACONV_DIR}"
	kosaio_echo "dcaconv updated."
}

function install() {
	__check_requeriments
	kosaio_echo "Installing dcaconv."
	clone
	build
	apply
	kosaio_echo "dcaconv has been installed."
}

function apply() {
	__is_installed
	__check_requeriments
	cd "${DCACONV_DIR}"
	make install
	kosaio_echo "dcaconv installed by make."
}

function uninstall() {
	__is_installed
	kosaio_echo "Uninstalling dcaconv."
	rm -rf "${DCACONV_DIR}"

	if [ -f "${DREAMCAST_BIN_PATH}/dcaconv" ]; then
		rm -f "${DREAMCAST_BIN_PATH}/dcaconv"
	fi

	crudini --set "${KOSAIO_CONFIG}" dreamcast_sdk dcaconv 0
	kosaio_echo "dcaconv has been uninstalled."
}

# Private functions

function __check_requeriments() {
	kosaio_require_packages build-essential
}

function __is_installed() {
	local IS_INSTALLED=$(crudini --get "${KOSAIO_CONFIG}" dreamcast_sdk dcaconv)

	if [ "${IS_INSTALLED}" = "0" ]; then
		kosaio_echo "dcaconv is not installled."
		exit 1
	fi

	if [ ! -d "${DCACONV_DIR}" ]; then
		kosaio_echo "dcaconv folder not found, is dcaconv installed?."
		exit 1
	fi
}