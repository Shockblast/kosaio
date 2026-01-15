#!/bin/bash
set -e

if [ "$KOSAIO_DEV_MODE" == "1" ]; then
	MAKEIP_DIR="${PROJECTS_DIR}/kosaio-dev/makeip"
else
	MAKEIP_DIR="${DREAMCAST_SDK_EXTRAS}/makeip"
fi

# Public functions

function info() {
	kosaio_echo "Name: makeip \n" \
		"Git: https://github.com/Dreamcast-Projects/makeip.git \n" \
		"Description: A tool to create IP.BIN boot files for Sega Dreamcast executables. This file contains metadata like the game title and is required for booting. \n" \
		"Note: This version is more up-to-date than the one integrated in Kallistios."
}

function clone() {
	kosaio_echo "Cloning makeip."
	kosaio_git_clone https://github.com/Dreamcast-Projects/makeip.git "${MAKEIP_DIR}"
	kosaio_echo "makeip has been cloned."
}

function build() {
	__is_installed
	__check_requeriments
	kosaio_echo "Re/Building makeip..."
	cd "${MAKEIP_DIR}/src"
	make -j$(nproc)
	kosaio_echo "makeip has been built."
}

function update() {
	__is_installed
	__check_requeriments
	kosaio_echo "Checking for makeip updates..."
	kosaio_git_common_update "${MAKEIP_DIR}"
	kosaio_echo "makeip updated."
}

function install() {
	__check_requeriments
	kosaio_echo "Installing makeip..."
	clone
	build
	apply
	kosaio_echo "makeip installation complete."
}

function apply() {
	__is_installed
	__check_requeriments
	cd "${MAKEIP_DIR}/src"
	make install
	kosaio_echo "makeip installed by make."
}

function diagnose() {
	kosaio_echo "Diagnosing makeip..."
	local errors=0

	if [ -d "${MAKEIP_DIR}" ]; then
		kosaio_print_status "PASS" "makeip source directory found."
	else
		kosaio_print_status "FAIL" "makeip source directory missing."
		((errors++))
	fi

	if [ -x "${DREAMCAST_BIN_PATH}/makeip" ]; then
		kosaio_print_status "PASS" "makeip binary found in PATH."
	else
		kosaio_print_status "FAIL" "makeip binary MISSING or NOT EXECUTABLE."
		((errors++))
	fi

	if [ "$KOSAIO_DEV_MODE" == "1" ]; then
		kosaio_print_status "INFO" "Developer Mode active."
		if [ -f "${MAKEIP_DIR}/src/makeip" ]; then
			 kosaio_print_status "PASS" "Local compiled binary found."
		else
			 kosaio_print_status "FAIL" "Local compiled binary MISSING. Run 'kosaio build makeip'."
			 ((errors++))
		fi
	fi

	if [ "$errors" -eq 0 ]; then
		return 0
	else
		return 1
	fi
}

function uninstall() {
	__is_installed
	kosaio_echo "Uninstalling makeip..."
	rm -rf "${MAKEIP_DIR}"

	if [ -f "${DREAMCAST_BIN_PATH}/makeip" ]; then
		rm -f "${DREAMCAST_BIN_PATH}/makeip"
	fi

	kosaio_echo "makeip uninstallation complete."
}

# Private functions

function __check_requeriments() {
	kosaio_require_packages libpng-dev
}

function __is_installed() {
	if [ ! -d "${MAKEIP_DIR}" ]; then
		kosaio_echo "makeip folder not found. Is it installed?"
		exit 1
	fi
}
