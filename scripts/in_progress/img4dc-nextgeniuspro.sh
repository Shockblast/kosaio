#!/bin/bash
# DDOES NOT COMPILE / CONTAINS ERRORS
set -e # Exit immediately if a command exits with a non-zero status.

IMG4DC_DIR="${DREAMCAST_SDK_EXTRAS}/img4dc"

function info() {
	kosaio-echo "Name: img4dc \n" \
		"Git: hhttps://github.com/nextgeniuspro/img4dc.git \n" \
		"Description: A collection of tools for working with various Dreamcast disc image formats like CDI and MDS. \n" \
		"Note-1: The original img4dc can be found here https://sourceforge.net/projects/img4dc/"
}

function dependencies() {
	kosaio-echo "Installing img4dc dependencies..."
	apt-get install -y --no-install-recommends libncurses5-dev
	kosaio-echo "img4dc dependencies installed..."
}

function copy-bin() {
	cp "mds4dc/mds4dc" "cdi4dc/cdi4dc" "${DREAMCAST_BIN_PATH}"
	kosaio-echo "img4dc copied to ${DREAMCAST_BIN_PATH}."
}

function clone() {
	kosaio-echo "Cloning img4dc."
	git clone --depth=1 --single-branch "https://github.com/nextgeniuspro/img4dc.git" "${IMG4DC_DIR}"
	kosaio-echo "img4dc has been cloned."
}

function build() {
	kosaio-echo "Re/Building img4dc..."
	cd "${IMG4DC_DIR}"
	./build.sh
	kosaio-echo "img4dc has been built."
}

function update() {
	kosaio-echo "Checking for img4dc updates..."
	kosaio-git-common-update "${IMG4DC_DIR}"
	kosaio-echo "img4dc updated"
}

function install() {
	kosaio-echo "Installing img4dc..."
	dependencies
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