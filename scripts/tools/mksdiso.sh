#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

MKSDISO_DIR="${DREAMCAST_SDK_EXTRAS}/mksdiso"

function info() {
	kosaio-echo "Name: mksdiso \n" \
		"Git: https://github.com/Nold360/mksdiso.git \n" \
		"Description: A tool to create bootable SD card images for ODEs (Optical Drive Emulators) like GDEmu. It allows running homebrew from an SD card instead of a CD-R."
}

function dependencies() {
	kosaio-echo "Installing mksdiso dependencies..."
	apt-get install -y --no-install-recommends p7zip wodim genisoimage
	kosaio-echo "mksdiso dependencies installed..."
}

function copy-bin() {
	cd "${MKSDISO_DIR}"
	make install
	kosaio-echo "mksdiso installed by make."
}

function clone() {
	kosaio-echo "Cloning mksdiso..."
	git clone --depth=1 --single-branch https://github.com/Nold360/mksdiso.git "${MKSDISO_DIR}"
	kosaio-echo "mksdiso has been cloned."
}

function build() {
	kosaio-echo "NOTE: mksdiso can only do install, uninstall and update on this script...\n" \
		"If you want to compile something or explore you will need to open the folder repository here -> (${MKSDISO_DIR})."
}

function update() {
	kosaio-echo "Checking for mksdiso updates..."
	kosaio-git-common-update "${MKSDISO_DIR}"
	kosaio-echo "mksdiso updated."
}

function install() {
	kosaio-echo "Installing mksdiso..."
	dependencies
	clone
	copy-bin
	kosaio-echo "mksdiso installation complete."
}

function uninstall() {
	kosaio-echo "Uninstalling mksdiso..."
	make uninstall
	kosaio-echo "mksdiso uninstallation complete.\n" \
		"Note: APT packages 'p7zip wodim genisoimage' were not removed."
}
