#!/bin/bash
set -e

if [ "$KOSAIO_DEV_MODE" == "1" ]; then
	FLYCAST_DIR="${PROJECTS_DIR}/kosaio-dev/flycast"
else
	FLYCAST_DIR="${DREAMCAST_SDK_EXTRAS}/flycast"
fi
FLYCAST_BIN_PATH="${PROJECTS_DIR}"

# Public functions

function info() {
	kosaio_echo "Name: Flycast \n" \
		"Git: https://github.com/flyinghead/flycast.git \n" \
		"Description: A multi-platform Sega Dreamcast, Naomi, and Atomiswave emulator. It's useful for debugging homebrew applications without needing the actual hardware. \n" \
		"Note-1: Requires Dreamcast BIOS files on the host machine. \n" \
		"Note-2: The clone and build process can be very slow."
}

function clone() {
	kosaio_echo "Cloning Flycast (dev branch, very slow)..."
	git clone --depth=1 --single-branch --recursive https://github.com/flyinghead/flycast.git -b dev "${FLYCAST_DIR}"
	kosaio_echo "Flycast has been cloned."
}

function build() {
	__is_installed
	__check_requeriments
	kosaio_echo "Re/Building Flycast (slow)..."
	cd "${FLYCAST_DIR}"

	if [ -d "build" ]; then
		rm -rf build
	fi

	mkdir -p build
	cd build
	cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_GDB_SERVER=ON ..
	make -j$(nproc)
	kosaio_echo "Flycast has been built."
}

function update() {
	__is_installed
	__check_requeriments
	kosaio_echo "Checking for Flycast updates..."
	kosaio_git_common_update "${FLYCAST_DIR}"
	cd "${FLYCAST_DIR}"
	git submodule update --init --recursive
	kosaio_echo "Flycast updated."
}

function install() {
	__check_requeriments
	kosaio_echo "Installing Flycast..."
	clone
	build
	apply
	kosaio_echo "Flycast installation complete.\n " \
		"You can find the executable in ${FLYCAST_BIN_PATH}\n " \
		"If build failed you can post a issue in flycast github.\n " \
		"Remember to provide the necessary BIOS files in the host OS."
}

function apply() {
	__is_installed
	__check_requeriments

	if [ ! -f "${FLYCAST_DIR}/build/flycast" ]; then
		echo "Error: Flycast build not found, build fail?" >&2
		exit 1
	fi

	cp "${FLYCAST_DIR}/build/flycast" "${FLYCAST_BIN_PATH}"
	kosaio_echo "Copied flycast bin to folder projects (host)."
}

function diagnose() {
    kosaio_echo "Diagnosing Flycast..."
    local errors=0

    if [ -d "${FLYCAST_DIR}" ]; then
        kosaio_print_status "PASS" "Flycast source directory found."
    else
        kosaio_print_status "FAIL" "Flycast source directory missing."
        ((errors++))
    fi

    if [ -f "${FLYCAST_BIN_PATH}/build/flycast" ]; then
        kosaio_print_status "PASS" "Flycast binary found in host projects folder."
    else
        kosaio_print_status "FAIL" "Flycast binary MISSING from projects folder."
        ((errors++))
    fi

    if [ "$KOSAIO_DEV_MODE" == "1" ]; then
        kosaio_print_status "INFO" "Developer Mode active."
        if [ -f "${FLYCAST_DIR}/build/flycast" ]; then
             kosaio_print_status "PASS" "Local compiled binary found."
        else
             kosaio_print_status "FAIL" "Local compiled binary MISSING. Run 'kosaio build flycast'."
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
	kosaio_echo "Uninstalling Flycast..."
	rm -rf "${FLYCAST_DIR}"

	if [ -f "${FLYCAST_BIN_PATH}" ]; then
		rm -rf "${FLYCAST_BIN_PATH}"
	fi

	kosaio_echo "Flycast uninstallation complete."
}

# Private functions

function __check_requeriments() {
	kosaio_require_packages libcurl4-openssl-dev libvulkan-dev libsdl2-dev
}

function __is_installed() {
	if [ ! -d "${FLYCAST_DIR}" ]; then
		kosaio_echo "flycast is not installed."
		exit 1
	fi
}
