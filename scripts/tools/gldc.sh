#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

GLDC_DIR="${DREAMCAST_SDK_EXTRAS}/GLdc"

function info() {
	kosaio-echo "Name: GLdc \n" \
		"Git: https://gitlab.com/simulant/GLdc.git \n" \
		"Description: An OpenGL implementation for the Dreamcast. GLdc allows developers to use the familiar OpenGL API for 3D graphics programming on the console. \n" \
		"Note: This is already instaled in kos-ports, this is only if you want to clone and developer GLdc."
}

function dependencies() {
	kosaio-echo "Nothing to install..."
}

function copy-bin() {
	kosaio-echo "Nothing to copy..."
}

function clone() {
	kosaio-echo "Cloning GLdc."
	git clone --depth=1 --single-branch "https://gitlab.com/simulant/GLdc.git" "${GLDC_DIR}"
	kosaio-echo "GLdc has been cloned."
}

function build() {
	kosaio-echo "Re/Building GLdc..."
	cd "${GLDC_DIR}"
	rm -rf "${GLDC_DIR}/dcbuild"
	mkdir -p dcbuild
	cd dcbuild
	cmake -DCMAKE_TOOLCHAIN_FILE=../toolchains/Dreamcast.cmake -G "Unix Makefiles" ..
	make -j$(nproc)
	kosaio-echo "GLdc has been built."
}

function update() {
	kosaio-echo "Checking for GLdc updates..."
	kosaio-git-common-update "${GLDC_DIR}"
	kosaio-echo "GLdc Update complete."
}

function install() {
	kosaio-echo "Installing GLdc..."
	clone
	build
	kosaio-echo "GLdc installation complete."
}

function uninstall() {
	# Remove the GLdc addon directory
	kosaio-echo "Uninstalling GLdc..."
	echo "Removing GLdc addon directory: ${GLDC_DIR}..."
	rm -rf "${GLDC_DIR}"
	kosaio-echo "GLdc uninstallation complete."
}
