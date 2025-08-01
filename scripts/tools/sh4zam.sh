#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

SH4ZAM_DIR="${DREAMCAST_SDK_EXTRAS}/sh4zam"

function info() {
	kosaio-echo "Name: sh4zam \n" \
		"Git: https://github.com/gyrovorbis/sh4zam.git \n" \
		"Description: A hand-optimized, general-purpose math and linear algebra library for harnessing the floating-point power of the SH4 processor in the Sega Dreamcast."
}

function dependencies() {
	kosaio-echo "Nothing to install..."
}

function copy-bin() {
	cd "${SH4ZAM_DIR}/build"
	make install
	kosaio-echo "sh4zam installed by make..."
}

function clone() {
	kosaio-echo "Cloning sh4zam..."
	git clone --depth=1 --single-branch https://github.com/gyrovorbis/sh4zam.git "${SH4ZAM_DIR}"
	kosaio-echo "sh4zam has been cloned."
}

function build() {
	kosaio-echo "Re/Building sh4zam..."
	cd "${SH4ZAM_DIR}"
	mkdir -p build
	cd build
	kos-cmake ..
	make -j$(nproc)
	kosaio-echo "sh4zam has been built."
}

function update() {
	kosaio-echo "Checking for sh4zam updates..."
	kosaio-git-common-update "${SH4ZAM_DIR}"
	kosaio-echo "sh4zam updated."
}

function install() {
	kosaio-echo "Installing sh4zam..."
	clone
	build
	copy-bin
	kosaio-echo "sh4zam installation complete."
}

function uninstall() {
	kosaio-echo "Uninstalling sh4zam..."
	kosaio-check-folder-exist "${SH4ZAM_DIR}"
	kos-remove-folder "${SH4ZAM_DIR}"
	kosaio-echo "sh4zam uninstallation complete."
}
