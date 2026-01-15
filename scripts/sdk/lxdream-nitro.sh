#!/bin/bash
set -e

if [ "$KOSAIO_DEV_MODE" == "1" ]; then
	LXDREAM_DIR="${PROJECTS_DIR}/kosaio-dev/lxdream-nitro"
else
	LXDREAM_DIR="${DREAMCAST_SDK_EXTRAS}/lxdream-nitro"
fi
LXDREAM_BIN_PATH="${PROJECTS_DIR}"

# Public functions

function info() {
	kosaio_echo "Name: lxdream-nitro \n" \
		"Git: https://gitlab.com/simulant/community/lxdream-nitro.git \n" \
		"Description: A high-fidelity Dreamcast emulator (Community Edition). \n"
}

function clone() {
	kosaio_echo "Cloning lxdream-nitro..."
	kosaio_git_clone --recursive https://gitlab.com/simulant/community/lxdream-nitro.git "${LXDREAM_DIR}"
	kosaio_echo "lxdream-nitro has been cloned."
}

function build() {
	__is_installed
	__check_requeriments
	kosaio_echo "Re/Building lxdream-nitro..."
	cd "${LXDREAM_DIR}"

	if [ -d "build" ]; then
		rm -rf build
	fi

	mkdir -p build
	meson setup build
	meson compile -C build
	kosaio_echo "lxdream-nitro has been built."
}

function update() {
	__is_installed
	__check_requeriments
	kosaio_echo "Checking for lxdream-nitro updates..."
	kosaio_git_common_update "${LXDREAM_DIR}"
	cd "${LXDREAM_DIR}"
	git submodule update --init --recursive
	kosaio_echo "lxdream-nitro updated."
}

function install() {
	__check_requeriments
	kosaio_echo "Installing lxdream-nitro..."
	clone
	build
	apply
	kosaio_echo "lxdream-nitro installation complete.\n " \
		"You can find the executable in ${LXDREAM_BIN_PATH}"
}

function apply() {
	__is_installed
	__check_requeriments

	if [ ! -f "${LXDREAM_DIR}/build/lxdream-nitro" ]; then
		echo "Error: lxdream-nitro build not found, build fail?" >&2
		exit 1
	fi

	cp "${LXDREAM_DIR}/build/lxdream-nitro" "${LXDREAM_BIN_PATH}"
	kosaio_echo "Copied lxdream-nitro bin to folder projects (host)."
}

function diagnose() {
	kosaio_echo "Diagnosing lxdream-nitro..."
	local errors=0

	if [ -d "${LXDREAM_DIR}" ]; then
		kosaio_print_status "PASS" "lxdream-nitro source directory found."
	else
		kosaio_print_status "FAIL" "lxdream-nitro source directory missing."
		((errors++))
	fi

	if [ -f "${LXDREAM_BIN_PATH}/lxdream-nitro" ]; then
		kosaio_print_status "PASS" "lxdream-nitro binary found in host projects folder."
	else
		kosaio_print_status "FAIL" "lxdream-nitro binary MISSING from projects folder."
		((errors++))
	fi

	if [ "$KOSAIO_DEV_MODE" == "1" ]; then
		kosaio_print_status "INFO" "Developer Mode active."
		if [ -f "${LXDREAM_DIR}/build/lxdream-nitro" ]; then
			 kosaio_print_status "PASS" "Local compiled binary found."
		else
			 kosaio_print_status "FAIL" "Local compiled binary MISSING. Run 'kosaio build lxdream-nitro'."
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
	kosaio_echo "Uninstalling lxdream-nitro..."
	rm -rf "${LXDREAM_DIR}"

	if [ -f "${LXDREAM_BIN_PATH}/lxdream-nitro" ]; then
		rm -rf "${LXDREAM_BIN_PATH}/lxdream-nitro"
	fi

	kosaio_echo "lxdream-nitro uninstallation complete."
}

# Private functions

function __check_requeriments() {
	kosaio_require_packages libgtk-3-dev meson ninja-build
}

function __is_installed() {
	if [ ! -d "${LXDREAM_DIR}" ]; then
		kosaio_echo "lxdream-nitro is not installed."
		exit 1
	fi
}
