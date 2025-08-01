#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

IMG4DC_DIR="${DREAMCAST_SDK_EXTRAS}/img4dc"

function info() {
	kosaio-echo "Name: img4dc \n" \
		"Git: https://github.com/kazade/img4dc.git \n" \
		"Description: A collection of tools for working with various Dreamcast disc image formats like CDI and MDS."
}

function dependencies() {
	kosaio-echo "Nothing to install..."
}

function copy-bin() {
	cp "build/mds4dc/mds4dc" "build/cdi4dc/cdi4dc" "${DREAMCAST_BIN_PATH}"
	kosaio-echo "img4dc copied."
}

function clone() {
	kosaio-echo "Cloning img4dc."
	git clone --depth=1 --single-branch "https://github.com/kazade/img4dc.git" "${IMG4DC_DIR}"
	kosaio-echo "img4dc has been cloned."
}

function build() {
	kosaio-echo "Re/Building img4dc..."
	cd "${IMG4DC_DIR}"
	mkdir -p build
	cd build
	cmake ..
	make -j$(nproc)
	kosaio-echo "img4dc has been built."
}

function update() {
	kosaio-echo "Checking for img4dc updates..."
	kosaio-git-common-update "${IMG4DC_DIR}"
	kosaio-echo "img4dc updated"
}

function install() {
	kosaio-echo "Installing img4dc..."
	clone
	build
	copy-bin
	kosaio-echo "img4dc installation complete."
}

function uninstall() {
	kosaio-echo "Uninstalling img4dc..."
	rm -rf "${IMG4DC_DIR}"
	rm -f "${DREAMCAST_BIN_PATH}/mds4dc" "${DREAMCAST_BIN_PATH}/cdi4dc"
	kosaio-echo "img4dc uninstallation complete."
}