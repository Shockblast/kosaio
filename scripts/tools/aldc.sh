#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

ALDC_DIR="${DREAMCAST_SDK_EXTRAS}/Aldc"

function info() {
	kosaio-echo "Name: ALdc \n" \
		"Git: https://gitlab.com/simulant/aldc.git \n" \
		"Description: An OpenAL implementation for the Dreamcast. ALdc allows developers to use the familiar OpenAL API for 3D audio programming on the console. \n" \
		"Note: This is already instaled in kos-ports, this is only if you want to clone and developer ALdc."
}

function dependencies() {
	kosaio-echo "Nothing to install..."
}

function copy-bin() {
	kosaio-echo "Nothing to copy..."
}

function clone() {
	kosaio-echo "Cloning ALdc."
	git clone --depth=1 --single-branch "https://gitlab.com/simulant/aldc.git" "${ALDC_DIR}"
	kosaio-echo "ALdc has been cloned."
}

function build() {
	kosaio-echo "Re/Building ALdc..."
	cd "${ALDC_DIR}"
	rm -rf builddir
	mkdir -p builddir
	cd builddir
	cmake -DCMAKE_TOOLCHAIN_FILE=../toolchains/Dreamcast.cmake -DCMAKE_BUILD_TYPE=Release ..
	make -j$(nproc)
	kosaio-echo "ALdc has been built."
}

function update() {
	kosaio-echo "Checking for ALdc updates..."
	kosaio-git-common-update "${ALDC_DIR}"
	kosaio-echo "ALdc Update complete."
}

function install() {
	kosaio-echo "Installing ALdc..."
	clone
	build
	kosaio-echo "ALdc installation complete."
}

function uninstall() {
	# Remove the ALdc addon directory
	kosaio-echo "Uninstalling ALdc..."
	echo "Removing ALdc addon directory: ${ALDC_DIR}..."
	rm -rf "${ALDC_DIR}"
	kosaio-echo "ALdc uninstallation complete."
}
