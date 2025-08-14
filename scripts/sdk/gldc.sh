#!/bin/bash
set -e

GLDC_DIR="${DREAMCAST_SDK_EXTRAS}/GLdc"

# Public functions

function info() {
	kosaio_echo "Name: GLdc \n" \
		"Git: https://gitlab.com/simulant/GLdc.git \n" \
		"Description: An OpenGL implementation for the Dreamcast. GLdc allows developers to use the familiar OpenGL API for 3D graphics programming on the console. \n" \
		"Note: This is already instaled in kos-ports, this is only if you want to clone and developer GLdc."
}

function clone() {
	kosaio_echo "Cloning GLdc."
	git clone --depth=1 --single-branch https://gitlab.com/simulant/GLdc.git "${GLDC_DIR}"
	crudini --set "${KOSAIO_CONFIG}" dreamcast_sdk gldc 1
	kosaio_echo "GLdc has been cloned."
}

function build() {
	__is_installed
	__check_requeriments
	kosaio_echo "Re/Building GLdc..."
	cd "${GLDC_DIR}"

	if [ -d "dcbuild" ]; then
		rm -rf "dcbuild"
	fi

	mkdir -p "dcbuild"
	cd "dcbuild"
	cmake -DCMAKE_TOOLCHAIN_FILE=../toolchains/Dreamcast.cmake -G "Unix Makefiles" ..
	make -j$(nproc)
	kosaio_echo "GLdc has been built."
}

function update() {
	__is_installed
	__check_requeriments
	kosaio_echo "Checking for GLdc updates..."
	kosaio_git_common_update "${GLDC_DIR}"
	kosaio_echo "GLdc Update complete."
}

function install() {
	__check_requeriments
	kosaio_echo "Installing GLdc..."
	clone
	build
	apply
	kosaio_echo "GLdc installation complete."
}

function apply() {
	__check_requeriments
	__is_installed
	kosaio_echo "Nothing to copy..."
}

function uninstall() {
	__is_installed
	kosaio_echo "Uninstalling GLdc..."
	rm -rf "${GLDC_DIR}"
	crudini --set "${KOSAIO_CONFIG}" dreamcast_sdk gldc 0
	kosaio_echo "GLdc uninstallation complete."
}

# Private functions

function __check_requeriments() {
	local IS_INSTALLED=$(crudini --get "${KOSAIO_CONFIG}" dreamcast_sdk kos)

	if [ "${IS_INSTALLED}" = "0" ]; then
		kosaio_echo "KOS is required to use/compile GLdc."
		exit 1
	fi
}

function __is_installed() {
	local IS_INSTALLED=$(crudini --get "${KOSAIO_CONFIG}" dreamcast_sdk gldc)

	if [ "${IS_INSTALLED}" = "0" ]; then
		kosaio_echo "GLdc is not installled."
		exit 1
	fi

	if [ ! -d "${GLDC_DIR}" ]; then
		kosaio_echo "GLdc folder not found, is GLdc installed?."
		exit 1
	fi
}
