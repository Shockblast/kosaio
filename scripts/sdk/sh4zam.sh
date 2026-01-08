#!/bin/bash
set -e

if [ "$KOSAIO_DEV_MODE" == "1" ]; then
	SH4ZAM_DIR="${PROJECTS_DIR}/kosaio-dev/sh4zam"
else
	SH4ZAM_DIR="${DREAMCAST_SDK_EXTRAS}/sh4zam"
fi

# Public functions

function info() {
	kosaio_echo "Name: sh4zam \n" \
		"Git: https://github.com/gyrovorbis/sh4zam.git \n" \
		"Description: A hand-optimized, general-purpose math and linear algebra library for harnessing the floating-point power of the SH4 processor in the Sega Dreamcast. \n" \
		"Note: Kos is required to use sh4zam"
}

function clone() {
	kosaio_echo "Cloning sh4zam..."
	git clone --depth=1 --single-branch https://github.com/gyrovorbis/sh4zam.git "${SH4ZAM_DIR}"
	kosaio_echo "sh4zam has been cloned."
}

function build() {
	__is_installed
	__check_requeriments
	kosaio_echo "Re/Building sh4zam..."
	cd "${SH4ZAM_DIR}"
	make -f Makefile clean
	mkdir -p build
	cd build
	kos-cmake ..
	make
	kosaio_echo "sh4zam has been built."
}

function update() {
	__is_installed
	__check_requeriments
	kosaio_echo "Checking for sh4zam updates..."
	kosaio_git_common_update "${SH4ZAM_DIR}"
	kosaio_echo "sh4zam updated."
}

function install() {
	__check_requeriments
	kosaio_echo "Installing sh4zam..."
	clone
	build
	apply
	kosaio_echo "sh4zam installation complete."
}

function apply() {
	__is_installed
	__check_requeriments
	cd "${SH4ZAM_DIR}/build"
	make install
	kosaio_echo "sh4zam installed by make..."
}

function diagnose() {
    kosaio_echo "Diagnosing sh4zam..."
    local errors=0
    local lib_path

    if [ "$KOSAIO_DEV_MODE" == "1" ]; then
        lib_path="${SH4ZAM_DIR}/build/libsh4zam.a"
        kosaio_print_status "INFO" "Developer Mode active."
    else
        lib_path="${DREAMCAST_SDK}/kos/addons/lib/dreamcast/libsh4zam.a"
        kosaio_print_status "INFO" "Stable Mode active."
    fi

    if [ -d "${SH4ZAM_DIR}" ]; then
        kosaio_print_status "PASS" "sh4zam source directory found."
    else
        kosaio_print_status "FAIL" "sh4zam source directory missing."
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
	kosaio_echo "Uninstalling sh4zam..."
	cd "${SH4ZAM_DIR}"
	make -f Makefile uninstall
	cd ..
	rm -rf "${SH4ZAM_DIR}"
	kosaio_echo "Sh4zam uninstallation complete."
}

# Private functions

function __check_requeriments() {
	if [ ! -f "${DREAMCAST_SDK}/kos/environ.sh" ]; then
		kosaio_echo "KOS is required to compile/use Sh4zam (environ.sh not found)."
		exit 1
	fi
}

function __is_installed() {
	if [ ! -d "${SH4ZAM_DIR}" ]; then
		kosaio_echo "Sh4zam folder not found. Is it installed?"
		exit 1
	fi
}
