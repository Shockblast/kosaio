#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

DCLOADSERIAL_DIR="${DREAMCAST_SDK_EXTRAS}/dcload-serial"

function info() {
	kosaio-echo "Name: dcload-serial \n" \
		"Git: https://github.com/KallistiOS/dcload-serial.git \n" \
		"Description: A tool for uploading homebrew applications to the Sega Dreamcast over a serial connection. This is an alternative to dcload-ip, useful for developers using a serial cable for communication."
}

function dependencies() {
	kosaio-echo "Nothing to install..."
}

function copy-bin() {
	cd "${DCLOADSERIAL_DIR}"
	make install
	kosaio-echo "dcload-serial installed by make."
}

function clone() {
	kosaio-echo "Cloning dcload-serial..."
	git clone --depth=1 --single-branch https://github.com/KallistiOS/dcload-serial.git "${DCLOADSERIAL_DIR}"
	kosaio-echo "dcload-serial has cloned"
}

function build() {
	kosaio-echo "Building dcload-serial..."
	cd "${DCLOADSERIAL_DIR}"
	make -j$(nproc)
	kosaio-echo "dcload-serial has build."
}

function update() {
	kosaio-echo "Checking for dcload-serial updates..."
	kosaio-git-common-update "${DCLOADSERIAL_DIR}"
	kosaio-echo "dcload-serial updated"
}

function install() {
	kosaio-echo "Installing dcload-serial."
	clone
	build
	copy-bin
	kosaio-echo "dcload-serial has been installed"
}

function uninstall() {
	kosaio-echo "Uninstalling dcload-serial."
	rm -rf "${DCLOADSERIAL_DIR}"
	rm -f "${DREAMCAST_BIN_PATH}/dc-tool-serial"
	kosaio-echo "dcload-serial has been uninstalled"
}
