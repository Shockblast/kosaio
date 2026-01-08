#!/bin/bash
set -e

if [ "$KOSAIO_DEV_MODE" == "1" ]; then
	ALDC_DIR="${PROJECTS_DIR}/kosaio-dev/aldc"
else
	ALDC_DIR="${DREAMCAST_SDK_EXTRAS}/Aldc"
fi

# Public functions

function info() {
	kosaio_echo "Name: ALdc \n" \
		"Git: https://gitlab.com/simulant/aldc.git \n" \
		"Description: An OpenAL implementation for the Dreamcast. ALdc allows developers to use the familiar OpenAL API for 3D audio programming on the console. \n" \
		"Note: This is already instaled in kos-ports, this is only if you want to clone and developer ALdc."
}

function clone() {
	kosaio_echo "Cloning ALdc."
	git clone --depth=1 --single-branch https://gitlab.com/simulant/aldc.git "${ALDC_DIR}"
	kosaio_echo "ALdc has been cloned."
}

function build() {
	__is_installed
	__check_requeriments
	kosaio_echo "Re/Building ALdc..."
	cd "${ALDC_DIR}"

	if [ -d "builddir" ]; then
		rm -rf "builddir"
	fi

	mkdir -p "builddir"
	cd "builddir"
	cmake -DCMAKE_TOOLCHAIN_FILE=../toolchains/Dreamcast.cmake -DCMAKE_BUILD_TYPE=Release ..
	make -j$(nproc)
	kosaio_echo "ALdc has been built."
}

function update() {
	__is_installed
	__check_requeriments
	kosaio_echo "Checking for ALdc updates..."
	kosaio_git_common_update "${ALDC_DIR}"
	kosaio_echo "ALdc Update complete."
}

function install() {
	__check_requeriments
	kosaio_echo "Installing ALdc..."
	clone
	build
	apply
	kosaio_echo "ALdc installation complete."
}

function apply() {
	__is_installed
	__check_requeriments
	kosaio_echo "Nothing to copy..."
}

function diagnose() {
    kosaio_echo "Diagnosing ALdc..."
    local errors=0
    local lib_path

    if [ "$KOSAIO_DEV_MODE" == "1" ]; then
        lib_path="${ALDC_DIR}/builddir/libaldc.a"
        kosaio_print_status "INFO" "Developer Mode active."
    else
        lib_path="${DREAMCAST_SDK}/kos/addons/lib/dreamcast/libaldc.a"
        kosaio_print_status "INFO" "Stable Mode active."
    fi

    if [ -d "${ALDC_DIR}" ]; then
        kosaio_print_status "PASS" "ALdc source directory found."
    else
        kosaio_print_status "FAIL" "ALdc source directory missing."
        ((errors++))
    fi

    if [ -f "$lib_path" ]; then
        kosaio_print_status "PASS" "Compiled library found: $(basename "$lib_path")"
    else
        kosaio_print_status "FAIL" "Compiled library MISSING."
        ((errors++))
    fi

    if [ "$errors" -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

function uninstall() {
	__is_installed
	kosaio_echo "Uninstalling ALdc..."
	rm -rf "${ALDC_DIR}"
	kosaio_echo "ALdc uninstallation complete."
}

# Private functions

function __check_requeriments() {
	if [ ! -f "${DREAMCAST_SDK}/kos/environ.sh" ]; then
		kosaio_echo "KOS is required to use/compile ALdc (environ.sh not found)."
		exit 1
	fi
}

function __is_installed() {
	if [ ! -d "${ALDC_DIR}" ]; then
		kosaio_echo "ALdc folder not found. Is it installed?"
		exit 1
	fi
}
