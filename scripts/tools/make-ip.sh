#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

MAKEIP_DIR="${DREAMCAST_SDK_EXTRAS}/makeip"

function info() {
	kosaio-echo "Name: makeip \n" \
		"Git: https://github.com/Dreamcast-Projects/makeip.git \n" \
		"Description: A tool to create IP.BIN boot files for Sega Dreamcast executables. This file contains metadata like the game title and is required for booting."
}

function dependencies() {
	kosaio-echo "Installing make-ip dependencies..."
	apt-get install -y --no-install-recommends libpng-dev
	kosaio-echo "make-ip dependencies installed..."
}

function copy-bin() {
	cd "${MAKEIP_DIR}/src"
	make install
	kosaio-echo "makeip copy by make."
}

function clone() {
	kosaio-echo "Cloning makeip."
	git clone --depth=1 --single-branch "https://github.com/Dreamcast-Projects/makeip.git" "${MAKEIP_DIR}"
	kosaio-echo "makeip has been cloned."
}

function build() {
	kosaio-echo "Re/Building makeip..."
	cd "${MAKEIP_DIR}/src"
	make -j$(nproc)
	kosaio-echo "makeip has been built."
}

function update() {
	kosaio-echo "Checking for makeip updates..."
	kosaio-git-common-update "${MAKEIP_DIR}"
	kosaio-echo "makeip updated"
}

function install() {
	kosaio-echo "Installing makeip..."
	dependencies
	clone
	build
	copy-bin
	kosaio-echo "makeip installation complete."
}

function uninstall() {
	kosaio-echo "Uninstalling makeip..."
	rm -rf "${MAKEIP_DIR}"
	rm -f "${DREAMCAST_BIN_PATH}/makeip"
	kosaio-echo "makeip uninstallation complete."
}
