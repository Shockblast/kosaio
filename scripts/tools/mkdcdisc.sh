#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

MKDCDISC_DIR="${DREAMCAST_SDK_EXTRAS}/mkdcdisc"

function info() {
	kosaio-echo "Name: mkdcdisc \n" \
		"Git: https://gitlab.com/simulant/mkdcdisc.git \n" \
		"Description: A tool to create self-booting CDI disc images for the Sega Dreamcast. It simplifies the process of packaging a homebrew project into a burnable image."
}

function dependencies() {
	kosaio-echo "Installing mkdcdisc dependencies..."
	apt-get install -y --no-install-recommends git meson build-essential pkg-config libisofs libisofs-dev ninja-build
	kosaio-echo "mkdcdisc dependencies installed..."
}

function copy-bin() {
	kosaio-check-file-exist "${MKDCDISC_DIR}/builddir/mkdcdisc"
	cp "${MKDCDISC_DIR}/builddir/mkdcdisc" "${DREAMCAST_BIN_PATH}"
}

function clone() {
	kosaio-echo "Cloning mkdcdisc..."
	git clone --depth=1 --single-branch https://gitlab.com/simulant/mkdcdisc.git "${MKDCDISC_DIR}"
	kosaio-echo "mkdcdisc has been cloned."
}

function build() {
	kosaio-echo "Re/Building mkdcdisc..."
	cd "${MKDCDISC_DIR}"
	meson setup builddir
	meson compile -C builddir
	kosaio-echo "mkdcdisc has been built."
}

function update() {
	kosaio-echo "Checking for mkdcdisc updates..."
	kosaio-git-common-update "${MKDCDISC_DIR}"
	kosaio-echo "mkdcdisc updated"
}

function install() {
	kosaio-echo "Installing mkdcdisc..."
	echo "Installing mkdcdisc dependencies..."
	dependencies
	clone
	build
	copy-bin
	kosaio-echo "mkdcdisc installation complete."
}

function uninstall() {
	kosaio-echo "Uninstalling mkdcdisc..."
	kosaio-check-folder-exist "${MKDCDISC_DIR}"
	rm -rf "${MKDCDISC_DIR}"
	kosaio-check-file-exist "${DREAMCAST_BIN_PATH}/mkdcdisc"
	rm -f "${DREAMCAST_BIN_PATH}/mkdcdisc"
	kosaio-echo "mkdcdisc uninstallation complete."
}
