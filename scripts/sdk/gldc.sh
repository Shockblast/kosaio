#!/bin/bash
set -e

if [ "$KOSAIO_DEV_MODE" == "1" ]; then
	GLDC_DIR="${PROJECTS_DIR}/kosaio-dev/gldc"
else
	GLDC_DIR="${DREAMCAST_SDK_EXTRAS}/GLdc"
fi

# Public functions

function info() {
	kosaio_echo "Name: GLdc \n" \
		"Git: https://gitlab.com/simulant/GLdc.git \n" \
		"Description: An OpenGL implementation for the Dreamcast. GLdc allows developers to use the familiar OpenGL API for 3D graphics programming on the console. \n" \
		"Note: This is already instaled in kos-ports, this is only if you want to clone and developer GLdc."
}

function clone() {
	kosaio_echo "Cloning GLdc."
	kosaio_git_clone https://gitlab.com/simulant/GLdc.git "${GLDC_DIR}"
	kosaio_echo "GLdc has been cloned."
}

function build() {
	__is_installed
	__check_requeriments
	kosaio_echo "Re/Building GLdc..."
	cd "${GLDC_DIR}"

	if [ -d "dcbuild" ]; then
		rm -rf "dcbuild"
	fi

	mkdir -p "dcbuild"
	cd "dcbuild"
	cmake -DCMAKE_TOOLCHAIN_FILE=../toolchains/Dreamcast.cmake -G "Unix Makefiles" ..
	make -j$(nproc)
	kosaio_echo "GLdc has been built."
}

function update() {
	__is_installed
	__check_requeriments
	kosaio_echo "Checking for GLdc updates..."
	kosaio_git_common_update "${GLDC_DIR}"
	kosaio_echo "GLdc Update complete."
}

function install() {
	__check_requeriments
	kosaio_echo "Installing GLdc..."
	clone
	build
	apply
	kosaio_echo "GLdc installation complete."
}

function apply() {
	__check_requeriments
	__is_installed
	kosaio_echo "Nothing to copy..."
}

function diagnose() {
    kosaio_echo "Diagnosing GLdc..."
    local errors=0
    local lib_path

    if [ "$KOSAIO_DEV_MODE" == "1" ]; then
        lib_path="${GLDC_DIR}/dcbuild/libGLdc.a"
        kosaio_print_status "INFO" "Developer Mode active."
    else
        lib_path="${DREAMCAST_SDK}/kos/addons/lib/dreamcast/libGLdc.a"
        kosaio_print_status "INFO" "Stable Mode active."
    fi

    if [ -d "${GLDC_DIR}" ]; then
        kosaio_print_status "PASS" "GLdc source directory found."
    else
        kosaio_print_status "FAIL" "GLdc source directory missing."
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
	kosaio_echo "Uninstalling GLdc..."
	rm -rf "${GLDC_DIR}"
	kosaio_echo "GLdc uninstallation complete."
}

# Private functions

function __check_requeriments() {
    if [ ! -f "${DREAMCAST_SDK}/kos/environ.sh" ]; then
		kosaio_echo "KOS is required to use/compile GLdc (environ.sh not found)."
		exit 1
	fi
}

function __is_installed() {
	if [ ! -d "${GLDC_DIR}" ]; then
		kosaio_echo "GLdc folder not found. Is it installed?"
		exit 1
	fi
}
