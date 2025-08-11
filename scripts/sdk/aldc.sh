#!/bin/bash
set -e

ALDC_DIR="${DREAMCAST_SDK_EXTRAS}/Aldc"

# Public functions

function info() {
	kosaio_echo "Name: ALdc \n" \
		"Git: https://gitlab.com/simulant/aldc.git \n" \
		"Description: An OpenAL implementation for the Dreamcast. ALdc allows developers to use the familiar OpenAL API for 3D audio programming on the console. \n" \
		"Note: This is already instaled in kos-ports, this is only if you want to clone and developer ALdc."
}

function clone() {
	kosaio_echo "Cloning ALdc."
	git clone --depth=1 --single-branch "https://gitlab.com/simulant/aldc.git" "${ALDC_DIR}"
	crudini --set "${KOSAIO_CONFIG}" dreamcast_sdk aldc 1
	kosaio_echo "ALdc has been cloned."
}

function build() {
	__is_installed
	__check_requeriments
	kosaio_echo "Re/Building ALdc..."
	cd "${ALDC_DIR}"

	if [ -d "builddir" ]; then
		rm -rf "builddir"
	fi

	mkdir -p "builddir"
	cd "builddir"
	cmake -DCMAKE_TOOLCHAIN_FILE=../toolchains/Dreamcast.cmake -DCMAKE_BUILD_TYPE=Release ..
	make -j$(nproc)
	kosaio_echo "ALdc has been built."
}

function update() {
	__is_installed
	__check_requeriments
	kosaio_echo "Checking for ALdc updates..."
	kosaio_git_common_update "${ALDC_DIR}"
	kosaio_echo "ALdc Update complete."
}

function install() {
	__check_requeriments
	kosaio_echo "Installing ALdc..."
	clone
	build
	apply
	kosaio_echo "ALdc installation complete."
}

function apply() {
	__is_installed
	__check_requeriments
	kosaio_echo "Nothing to copy..."
}

function uninstall() {
	__is_installed
	kosaio_echo "Uninstalling ALdc..."
	rm -rf "${ALDC_DIR}"
	crudini --set "${KOSAIO_CONFIG}" dreamcast_sdk aldc 0
	kosaio_echo "ALdc uninstallation complete."
}

# Private functions

function __check_requeriments() {
	local IS_INSTALLED=$(crudini --get "${KOSAIO_CONFIG}" dreamcast_sdk kos)

	if [ "${IS_INSTALLED}" = "0" ]; then
		kosaio_echo "KOS is required to use/compile ALdc."
		exit 1
	fi
}

function __is_installed() {
	local IS_INSTALLED=$(crudini --get "${KOSAIO_CONFIG}" dreamcast_sdk aldc)

	if [ "${IS_INSTALLED}" = "0" ]; then
		kosaio_echo "ALdc is not installled."
		exit 1
	fi

	if [ ! -d "${ALDC_DIR}" ]; then
		kosaio_echo "ALdc folder not found, is ALdc installed?."
		exit 1
	fi
}
