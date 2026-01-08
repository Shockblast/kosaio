#!/bin/bash
set -e

if [ "$KOSAIO_DEV_MODE" == "1" ]; then
	KOS_PORTS_DIR="${PROJECTS_DIR}/kosaio-dev/kos-ports"
else
	KOS_PORTS_DIR="${DREAMCAST_SDK}/kos-ports"
fi

# Public functions

function info() {
	kosaio_echo "Name: KOS-PORTS \n" \
		"Git: https://github.com/KallistiOS/kos-ports \n" \
		"Description: KOS-PORTS is a collection of third-party libraries ported to work with KOS, simplifying development by providing common tools for graphics, sound, and more.\n" \
		"Note: The 'build' and 'update' commands can be very time-consuming."
}

function clone() {
	kosaio_echo "Cloning KOS-PORTS..."
	git clone --depth=1 --single-branch --recursive https://github.com/KallistiOS/kos-ports "${KOS_PORTS_DIR}"
	kosaio_echo "KOS-PORTS has been cloned."
}

function build() {
	__is_installed
	__check_requeriments
	kosaio_echo "Build KOS-PORTS..."
	cd "${KOS_PORTS_DIR}/utils"
	./build-all.sh || true # avoid some libs contain errors
	kosaio_echo "KOS-PORTS builds."
}

function update() {
	__is_installed
	__check_requeriments
	kosaio_echo "Checking for KOS-PORTS updates..."
	kosaio_git_common_update "${KOS_PORTS_DIR}"
	cd "${KOS_PORTS_DIR}"
	git submodule update --init --recursive
	kosaio_echo "KOS-PORTS updated, now you can run 'kosaio kos-ports build'.\n" \
		"And now you can get up and go for coffee, this will take a while."
}

function install() {
	__check_requeriments
	kosaio_echo "Installing KOS-PORTS..."
	clone
	build
	apply
	kosaio_echo "KOS-PORTS installed."
}

function apply() {
	__is_installed
	__check_requeriments
	kosaio_echo "Nothing to copy..."
}

function diagnose() {
    kosaio_echo "Diagnosing KOS-PORTS..."
    local errors=0

    if [ -d "${KOS_PORTS_DIR}" ]; then
        kosaio_print_status "PASS" "KOS-PORTS directory found."
    else
        kosaio_print_status "FAIL" "KOS-PORTS directory missing."
        ((errors++))
    fi

    local indicator="${DREAMCAST_SDK}/kos/addons/lib/dreamcast/libpng.a"
    if [ -f "$indicator" ]; then
        kosaio_print_status "PASS" "Ports health indicator found: libpng.a"
    else
        kosaio_print_status "WARN" "libpng.a not found. Some ports might not be compiled."
    fi

    if [ "$errors" -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

function uninstall() {
	__is_installed
	kosaio_echo "Uninstalling KOS-PORTS..."
	cd "${KOS_PORTS_DIR}/utils"
	./uninstall-all.sh
	cd "/opt/projects"
	rm -rf "${KOS_PORTS_DIR}"
	kosaio_echo "KOS-PORTS Uninstalled."
}

# Private functions

function __check_requeriments() {
	kosaio_require_packages python3 python-is-python3

	if [ ! -f "${DREAMCAST_SDK}/kos/environ.sh" ]; then
		kosaio_echo "KOS is required to use/compile KOS-PORTS (environ.sh not found)."
		exit 1
	fi
}

function __is_installed() {
	if [ ! -d "${KOS_PORTS_DIR}" ]; then
		kosaio_echo "KOS-PORTS folder not found. Is it installed?"
		exit 1
	fi
}
