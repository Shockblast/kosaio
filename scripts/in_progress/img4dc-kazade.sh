#!/bin/bash
# DDOES NOT COMPILE / CONTAINS ERRORS
set -e

IMG4DC_DIR="${DREAMCAST_SDK_EXTRAS}/img4dc"

function info() {
	kosaio_echo "Name: img4dc \n" \
		"Git: https://github.com/kazade/img4dc.git \n" \
		"Description: A collection of tools for working with various Dreamcast disc image formats like CDI and MDS. \n" \
		"Note-1: The original img4dc can be found here https://sourceforge.net/projects/img4dc/"
}

function install_bin() {
	cp "build/mds4dc/mds4dc" "build/cdi4dc/cdi4dc" "${DREAMCAST_BIN_PATH}"
	kosaio_echo "img4dc copied to ${DREAMCAST_BIN_PATH}."
}

function clone() {
	kosaio_echo "Cloning img4dc."
	kosaio_git_clone "https://github.com/kazade/img4dc.git" "${IMG4DC_DIR}"
	kosaio_echo "img4dc has been cloned."
}

function build() {
	kosaio_echo "Re/Building img4dc..."
	cd "${IMG4DC_DIR}"
	mkdir -p build
	cd build
	cmake ..
	make -j$(nproc)
	kosaio_echo "img4dc has been built."
}

function update() {
	kosaio_echo "Checking for img4dc updates..."
	kosaio_git_common_update "${IMG4DC_DIR}"
	kosaio_echo "img4dc updated"
}

function install() {
	kosaio_echo "Installing img4dc..."
	clone
	build
	install_bin
	kosaio_echo "img4dc installation complete."
}

function uninstall() {
	kosaio_echo "Uninstalling img4dc..."
	rm -rf "${IMG4DC_DIR}"
	rm -f "${DREAMCAST_BIN_PATH}/mds4dc" "${DREAMCAST_BIN_PATH}/cdi4dc"
	kosaio_echo "img4dc uninstallation complete."
}
