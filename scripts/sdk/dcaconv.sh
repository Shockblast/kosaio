#!/bin/bash
set -e

if [ "$KOSAIO_DEV_MODE" == "1" ]; then
	DCACONV_DIR="${PROJECTS_DIR}/kosaio-dev/dcaconv"
else
	DCACONV_DIR="${DREAMCAST_SDK_EXTRAS}/dcaconv"
fi

# Public functions

function info() {
	kosaio_echo "Name: dcaconv \n" \
		"Git: https://github.com/TapamN/dcaconv.git \n" \
		"Description: dcaconv converts audio to a format for the Dreamcast's AICA."
}

function clone() {
	kosaio_echo "Cloning dcaconv..."
	git clone --depth=1 --single-branch https://github.com/TapamN/dcaconv.git "${DCACONV_DIR}"
	kosaio_echo "dcaconv has cloned."
}

function build() {
	__is_installed
	__check_requeriments
	kosaio_echo "Building dcaconv..."
	cd "${DCACONV_DIR}"
	make all -j$(nproc)
	kosaio_echo "dcaconv has build."
}

function update() {
	__is_installed
	__check_requeriments
	kosaio_echo "Checking for dcaconv updates..."
	kosaio_git_common_update "${DCACONV_DIR}"
	kosaio_echo "dcaconv updated."
}

function install() {
	__check_requeriments
	kosaio_echo "Installing dcaconv."
	clone
	build
	apply
	kosaio_echo "dcaconv has been installed."
}

function apply() {
	__is_installed
	__check_requeriments
	cd "${DCACONV_DIR}"
	cp "dcaconv" "${DREAMCAST_BIN_PATH}"
	kosaio_echo "dcaconv installed by copy."
}

function diagnose() {
    kosaio_echo "Diagnosing dcaconv..."
    local errors=0

    # 1. Directory presence
    if [ -d "${DCACONV_DIR}" ]; then
        kosaio_print_status "PASS" "dcaconv source directory found."
    else
        kosaio_print_status "FAIL" "dcaconv source directory missing."
        ((errors++))
    fi

    # 2. Binary presence
    if [ -x "${DREAMCAST_BIN_PATH}/dcaconv" ]; then
        kosaio_print_status "PASS" "dcaconv binary found in PATH."
    else
        kosaio_print_status "FAIL" "dcaconv binary MISSING or NOT EXECUTABLE."
        ((errors++))
    fi

    # 3. Dev Mode check
    if [ "$KOSAIO_DEV_MODE" == "1" ]; then
        kosaio_print_status "INFO" "Developer Mode active."
        if [ -f "${DCACONV_DIR}/dcaconv" ]; then
             kosaio_print_status "PASS" "Local compiled binary found."
        else
             kosaio_print_status "FAIL" "Local compiled binary MISSING. Run 'kosaio build dcaconv'."
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
	kosaio_echo "Uninstalling dcaconv."
	rm -rf "${DCACONV_DIR}"

	if [ -f "${DREAMCAST_BIN_PATH}/dcaconv" ]; then
		rm -f "${DREAMCAST_BIN_PATH}/dcaconv"
	fi

	kosaio_echo "dcaconv has been uninstalled."
}

# Private functions

function __check_requeriments() {
	kosaio_require_packages build-essential
}

function __is_installed() {
	if [ ! -d "${DCACONV_DIR}" ]; then
		kosaio_echo "dcaconv folder not found. Is it installed?"
		exit 1
	fi
}