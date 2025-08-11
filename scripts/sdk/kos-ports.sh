#!/bin/bash
set -e

KOS_PORTS_DIR="${DREAMCAST_SDK}/kos-ports"

# Public functions

function info() {
	kosaio_echo "Name: KOS-PORTS \n" \
		"Git: https://github.com/KallistiOS/kos-ports \n" \
		"Description: KOS-PORTS is a collection of third-party libraries ported to work with KOS, simplifying development by providing common tools for graphics, sound, and more.\n" \
		"Note: The 'build' and 'update' commands can be very time-consuming."
}

function clone() {
	kosaio_echo "Cloning KOS and KOS-PORTS..."
	git clone --depth=1 --single-branch --recursive https://github.com/KallistiOS/kos-ports "${KOS_PORTS_DIR}"
	crudini --set "${KOSAIO_CONFIG}" dreamcast_sdk kos-ports 1
	kosaio_echo "KOS and KOS-PORTS has been cloned."
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

function uninstall() {
	__is_installed
	kosaio_echo "Uninstalling KOS-PORTS..."
	rm -rf "${KOS_PORTS_DIR}"
	crudini --set "${KOSAIO_CONFIG}" dreamcast_sdk kos-ports 0
	kosaio_echo "KOS-PORTS Uninstalled."
}

# Private functions

function __check_requeriments() {
	local IS_INSTALLED=$(crudini --get "${KOSAIO_CONFIG}" dreamcast_sdk kos)

	if [ "${IS_INSTALLED}" = "0" ]; then
		kosaio_echo "KOS is required to use/compile KOS-PORTS."
		exit 1
	fi
}

function __is_installed() {
	local IS_INSTALLED=$(crudini --get "${KOSAIO_CONFIG}" dreamcast_sdk kos-ports)

	if [ "${IS_INSTALLED}" = "0" ]; then
		kosaio_echo "KOS-PORTS is not installled."
		exit 1
	fi

	if [ ! -d "${KOS_PORTS_DIR}" ]; then
		kosaio_echo "KOS-PORTS folder not found, is KOS-PORTS installed?."
		exit 1
	fi
}
