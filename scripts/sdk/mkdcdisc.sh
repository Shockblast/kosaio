#!/bin/bash
set -e

if [ "$KOSAIO_DEV_MODE" == "1" ]; then
	MKDCDISC_DIR="${PROJECTS_DIR}/kosaio-dev/mkdcdisc"
else
	MKDCDISC_DIR="${DREAMCAST_SDK_EXTRAS}/mkdcdisc"
fi

# Public functions

function info() {
	kosaio_echo "Name: mkdcdisc \n" \
		"Git: https://gitlab.com/simulant/mkdcdisc.git \n" \
		"Description: A tool to create self-booting CDI disc images for the Sega Dreamcast. It simplifies the process of packaging a homebrew project into a burnable image."
}

function clone() {
	kosaio_echo "Cloning mkdcdisc..."
	kosaio_git_clone https://gitlab.com/simulant/mkdcdisc.git "${MKDCDISC_DIR}"
	kosaio_echo "mkdcdisc has been cloned."
}

function build() {
	__is_installed
	__check_requeriments
	kosaio_echo "Re/Building mkdcdisc..."
	cd "${MKDCDISC_DIR}"
	meson setup builddir
	meson compile -C builddir
	kosaio_echo "mkdcdisc has been built."
}

function update() {
	__is_installed
	__check_requeriments
	kosaio_echo "Checking for mkdcdisc updates..."
	kosaio_git_common_update "${MKDCDISC_DIR}"
	kosaio_echo "mkdcdisc updated."
}

function install() {
	__check_requeriments
	kosaio_echo "Installing mkdcdisc..."
	clone
	build
	apply
	kosaio_echo "mkdcdisc installation complete."
}

function apply() {
	__is_installed
	__check_requeriments

	if [ ! -f "${MKDCDISC_DIR}/builddir/mkdcdisc" ]; then
		echo "Error: mkdcdisc build not found, build fail?" >&2
		exit 1
	fi

	cp "${MKDCDISC_DIR}/builddir/mkdcdisc" "${DREAMCAST_BIN_PATH}"
}

function diagnose() {
    kosaio_echo "Diagnosing mkdcdisc..."
    local errors=0

    if [ -d "${MKDCDISC_DIR}" ]; then
        kosaio_print_status "PASS" "mkdcdisc source directory found."
    else
        kosaio_print_status "FAIL" "mkdcdisc source directory missing."
        ((errors++))
    fi

    if [ -x "${DREAMCAST_BIN_PATH}/mkdcdisc" ]; then
        kosaio_print_status "PASS" "mkdcdisc binary found in PATH."
    else
        kosaio_print_status "FAIL" "mkdcdisc binary MISSING or NOT EXECUTABLE."
        ((errors++))
    fi

    if [ "$KOSAIO_DEV_MODE" == "1" ]; then
        kosaio_print_status "INFO" "Developer Mode active."
        if [ -f "${MKDCDISC_DIR}/builddir/mkdcdisc" ]; then
             kosaio_print_status "PASS" "Local compiled binary found."
        else
             kosaio_print_status "FAIL" "Local compiled binary MISSING. Run 'kosaio build mkdcdisc'."
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
	kosaio_echo "Uninstalling mkdcdisc..."

	rm -rf "${MKDCDISC_DIR}"

	if [ -f "${DREAMCAST_BIN_PATH}/mkdcdisc" ]; then
		rm -f "${DREAMCAST_BIN_PATH}/mkdcdisc"
	fi

	kosaio_echo "mkdcdisc uninstallation complete."
}

# Private functions

function __check_requeriments() {
	kosaio_require_packages git meson build-essential pkg-config libisofs-dev
}

function __is_installed() {
	if [ ! -d "${MKDCDISC_DIR}" ]; then
		kosaio_echo "mkdcdisc folder not found. Is it installed?"
		exit 1
	fi
}
