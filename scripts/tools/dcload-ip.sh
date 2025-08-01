#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

DCLOADIP_DIR="${DREAMCAST_SDK_EXTRAS}/dcload-ip"

function info() {
	kosaio-echo "Name: dcload-ip \n" \
		"Git: https://github.com/KallistiOS/dcload-ip.git \n" \
		"Description: A tool for uploading homebrew applications to the Sega Dreamcast over an IP network. This is essential for rapid development and debugging without burning a new CD for each test."
}

function dependencies() {
	kosaio-echo "Nothing to install..."
}

function copy-bin() {
	cd "${DCLOADIP_DIR}"
	make install
	kosaio-echo "dcload-ip installed by make."
}

function clone() {
	kosaio-echo "Cloning dcload-ip..."
	git clone --depth=1 --single-branch https://github.com/KallistiOS/dcload-ip.git "${DCLOADIP_DIR}"
	kosaio-echo "dcload-ip has cloned"
}

function build() {
	kosaio-echo "Building dcload-ip..."
	cd "${DCLOADIP_DIR}"
	make -j$(nproc)
	kosaio-echo "dcload-ip has build."
}

function update() {
	kosaio-echo "Checking for dcload-ip updates..."
	kosaio-git-common-update "${DCLOADIP_DIR}"
	kosaio-echo "dcload-ip updated"
}

function install() {
	kosaio-echo "Installing dcload-ip."
	clone
	build
	copy-bin
	kosaio-echo "dcload-ip has been installed."
}

function uninstall() {
	kosaio-echo "Uninstalling dcload-ip."
	rm -rf "${DCLOADIP_DIR}"
	rm -f "${DREAMCAST_BIN_PATH}/dc-tool-ip"
	kosaio-echo "dcload-ip has been uninstalled"
}
