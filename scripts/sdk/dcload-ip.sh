#!/bin/bash
set -e

if [ "$KOSAIO_DEV_MODE" == "1" ]; then
	DCLOADIP_DIR="${PROJECTS_DIR}/kosaio-dev/dcload-ip"
else
	DCLOADIP_DIR="${DREAMCAST_SDK_EXTRAS}/dcload-ip"
fi

# Public functions

function info() {
	kosaio_echo "Name: dcload-ip \n" \
		"Git: https://github.com/KallistiOS/dcload-ip.git \n" \
		"Description: A tool for uploading homebrew applications to the Sega Dreamcast over an IP network. This is essential for rapid development and debugging without burning a new CD for each test."
}

function clone() {
	kosaio_echo "Cloning dcload-ip..."
	kosaio_git_clone https://github.com/KallistiOS/dcload-ip.git "${DCLOADIP_DIR}"
	kosaio_echo "dcload-ip has cloned."
}

function build() {
	__is_installed
	__check_requeriments
	kosaio_echo "Building dcload-ip..."
	cd "${DCLOADIP_DIR}"
	make all -j$(nproc)
	kosaio_echo "dcload-ip has build."
}

function update() {
	__is_installed
	__check_requeriments
	kosaio_echo "Checking for dcload-ip updates..."
	kosaio_git_common_update "${DCLOADIP_DIR}"
	kosaio_echo "dcload-ip updated."
}

function install() {
	__check_requeriments
	kosaio_echo "Installing dcload-ip."
	clone
	build
	apply
	kosaio_echo "dcload-ip has been installed."
}

function apply() {
	__is_installed
	__check_requeriments
	cd "${DCLOADIP_DIR}"
	make install
	kosaio_echo "dcload-ip installed by make."
}

function diagnose() {
    kosaio_echo "Diagnosing dcload-ip..."
    local errors=0

    if [ -d "${DCLOADIP_DIR}" ]; then
        kosaio_print_status "PASS" "dcload-ip source directory found."
    else
        kosaio_print_status "FAIL" "dcload-ip source directory missing."
        ((errors++))
    fi

    if [ -x "${DREAMCAST_BIN_PATH}/dc-tool-ip" ]; then
        kosaio_print_status "PASS" "dc-tool-ip found in PATH."
    else
        kosaio_print_status "FAIL" "dc-tool-ip MISSING from PATH."
        ((errors++))
    fi

    if [ "$KOSAIO_DEV_MODE" == "1" ]; then
        kosaio_print_status "INFO" "Developer Mode active."
        if [ -f "${DCLOADIP_DIR}/target-src/1st_read/loader.bin" ] || [ -f "${DCLOADIP_DIR}/host-src/tool/dc-tool" ]; then
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
	kosaio_echo "Uninstalling dcload-ip."
	rm -rf "${DCLOADIP_DIR}"

	if [ -f "${DREAMCAST_BIN_PATH}/dc-tool-ip" ]; then
		rm -f "${DREAMCAST_BIN_PATH}/dc-tool-ip"
	fi

	kosaio_echo "dcload-ip has been uninstalled."
}

# Private functions

function __check_requeriments() {
	kosaio_require_packages wodim

    if [ ! -f "${DREAMCAST_SDK}/kos/environ.sh" ]; then
		kosaio_echo "KOS is required to compile/use dcload-ip (environ.sh not found)."
		exit 1
	fi
}

function __is_installed() {
	if [ ! -d "${DCLOADIP_DIR}" ]; then
		kosaio_echo "dcload-ip folder not found. Is it installed?"
		exit 1
	fi
}
