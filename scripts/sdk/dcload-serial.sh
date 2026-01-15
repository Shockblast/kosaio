#!/bin/bash
set -e

if [ "$KOSAIO_DEV_MODE" == "1" ]; then
	DCLOADSERIAL_DIR="${PROJECTS_DIR}/kosaio-dev/dcload-serial"
else
	DCLOADSERIAL_DIR="${DREAMCAST_SDK_EXTRAS}/dcload-serial"
fi

# Public functions

function info() {
	kosaio_echo "Name: dcload-serial \n" \
		"Git: https://github.com/KallistiOS/dcload-serial.git \n" \
		"Description: A tool for uploading homebrew applications to the Sega Dreamcast over a serial connection. This is an alternative to dcload-ip, useful for developers using a serial cable for communication."
}

function clone() {
	kosaio_echo "Cloning dcload-serial..."
	kosaio_git_clone https://github.com/KallistiOS/dcload-serial.git "${DCLOADSERIAL_DIR}"
	kosaio_echo "dcload-serial has cloned."
}

function build() {
	__is_installed
	__check_requeriments
	kosaio_echo "Building dcload-serial..."
	cd "${DCLOADSERIAL_DIR}"
	make -j$(nproc)
	kosaio_echo "dcload-serial has build."
}

function update() {
	__is_installed
	__check_requeriments
	kosaio_echo "Checking for dcload-serial updates..."
	kosaio_git_common_update "${DCLOADSERIAL_DIR}"
	kosaio_echo "dcload-serial updated."
}

function install() {
	__check_requeriments
	kosaio_echo "Installing dcload-serial."
	clone
	build
	apply
	kosaio_echo "dcload-serial has been installed."
}

function apply() {
	__is_installed
	__check_requeriments
	cd "${DCLOADSERIAL_DIR}"
	make install
	kosaio_echo "dcload-serial installed by make."
}

function diagnose() {
	kosaio_echo "Diagnosing dcload-serial..."
	local errors=0

	if [ -d "${DCLOADSERIAL_DIR}" ]; then
		kosaio_print_status "PASS" "dcload-serial source directory found."
	else
		kosaio_print_status "FAIL" "dcload-serial source directory missing."
		((errors++))
	fi

	if [ -x "${DREAMCAST_BIN_PATH}/dc-tool-serial" ]; then
		kosaio_print_status "PASS" "dc-tool-serial found in PATH."
	else
		kosaio_print_status "FAIL" "dc-tool-serial MISSING from PATH."
		((errors++))
	fi

	if [ "$KOSAIO_DEV_MODE" == "1" ]; then
		kosaio_print_status "INFO" "Developer Mode active."
		if [ -f "${DCLOADSERIAL_DIR}/target-src/1st_read/loader.bin" ] || [ -f "${DCLOADSERIAL_DIR}/host-src/tool/dc-tool" ]; then
			 kosaio_print_status "PASS" "Local source/build files found."
		else
			 kosaio_print_status "FAIL" "Local build files MISSING."
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
	kosaio_echo "Uninstalling dcload-serial."
	rm -rf "${DCLOADSERIAL_DIR}"

	if [ -f "${DREAMCAST_BIN_PATH}/dc-tool-serial" ]; then
		rm -f "${DREAMCAST_BIN_PATH}/dc-tool-serial"
	fi

	kosaio_echo "dcload-serial has been uninstalled."
}

# Private functions

function __check_requeriments() {
	if [ ! -f "${DREAMCAST_SDK}/kos/environ.sh" ]; then
		kosaio_echo "KOS is required to compile/use dcload-serial (environ.sh not found)."
		exit 1
	fi
}

function __is_installed() {
	if [ ! -d "${DCLOADSERIAL_DIR}" ]; then
		kosaio_echo "dcload-serial folder not found. Is it installed?"
		exit 1
	fi
}
