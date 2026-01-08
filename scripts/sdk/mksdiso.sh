#!/bin/bash
set -e

if [ "$KOSAIO_DEV_MODE" == "1" ]; then
	MKSDISO_DIR="${PROJECTS_DIR}/kosaio-dev/mksdiso"
else
	MKSDISO_DIR="${DREAMCAST_SDK_EXTRAS}/mksdiso"
fi

# Public functions

function info() {
	kosaio_echo "Name: mksdiso \n" \
		"Git: https://github.com/Nold360/mksdiso.git \n" \
		"Description: A tool to create bootable SD card images for ODEs (Optical Drive Emulators) like GDEmu. It allows running homebrew from an SD card instead of a CD-R."
}

function clone() {
	kosaio_echo "Cloning mksdiso..."
	git clone --depth=1 --single-branch https://github.com/Nold360/mksdiso.git "${MKSDISO_DIR}"
	kosaio_echo "mksdiso has been cloned."
}

function build() {
	__is_installed
	__check_requeriments
	kosaio_echo "NOTE: mksdiso can only do install, uninstall and update on this script...\n" \
		"If you want to compile something or explore you will need to open the folder repository here -> (${MKSDISO_DIR})."
}

function update() {
	__is_installed
	__check_requeriments
	kosaio_echo "Checking for mksdiso updates..."
	kosaio_git_common_update "${MKSDISO_DIR}"
	kosaio_echo "mksdiso updated."
}

function install() {
	__check_requeriments
	kosaio_echo "Installing mksdiso..."
	clone
	build
	apply
	kosaio_echo "mksdiso installation complete."
}

function apply() {
	__is_installed
	__check_requeriments
	cd "${MKSDISO_DIR}"
	make install
	kosaio_echo "mksdiso installed by make."
}

function diagnose() {
    kosaio_echo "Diagnosing mksdiso..."
    local errors=0

    if [ -d "${MKSDISO_DIR}" ]; then
        kosaio_print_status "PASS" "mksdiso source directory found."
    else
        kosaio_print_status "FAIL" "mksdiso source directory missing."
        ((errors++))
    fi

    if [ -x "${DREAMCAST_BIN_PATH}/mksdiso" ]; then
        kosaio_print_status "PASS" "mksdiso binary/script found in PATH."
    else
        kosaio_print_status "FAIL" "mksdiso MISSING from PATH."
        ((errors++))
    fi

    if [ "$KOSAIO_DEV_MODE" == "1" ]; then
        kosaio_print_status "INFO" "Developer Mode active."
    fi

    if [ "$errors" -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

function uninstall() {
	__is_installed
	kosaio_echo "Uninstalling mksdiso..."
	cd "${MKSDISO_DIR}"
	make uninstall
	cd ..
	rm -rf "${MKSDISO_DIR}"
	kosaio_echo "mksdiso uninstallation complete."

}

# Private functions

function __check_requeriments() {
	kosaio_require_packages p7zip wodim genisoimage
}

function __is_installed() {
	if [ ! -d "${MKSDISO_DIR}" ]; then
		kosaio_echo "mksdiso folder not found. Is it installed?"
		exit 1
	fi
}
