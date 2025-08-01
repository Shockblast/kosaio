#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

FLYCAST_DIR="${DREAMCAST_SDK_EXTRAS}/flycast"
FLYCAST_BIN_PATH="${PROJECTS_DIR}"

function info() {
	kosaio-echo "Name: Flycast \n" \
		"Git: https://github.com/flyinghead/flycast.git \n" \
		"Description: A multi-platform Sega Dreamcast, Naomi, and Atomiswave emulator. It's useful for debugging homebrew applications without needing the actual hardware. \n" \
		"Note-1: Requires Dreamcast BIOS files on the host machine. \n" \
		"Note-2: The clone and build process can be very slow."
}

function dependencies() {
	kosaio-echo "Installing Flycast dependencies..."
	apt-get install -y --no-install-recommends libcurl4-openssl-dev libvulkan-dev libsdl2-dev
	kosaio-echo "Flycast dependencies installed..."
}

function copy-bin() {
	kosaio-check-file-exist "${FLYCAST_DIR}/build/flycast"
	cp "${FLYCAST_DIR}/build/flycast" "${FLYCAST_BIN_PATH}"
	kosaio-echo "Copy flycast bin to folder project done."
}

function clone() {
	kosaio-echo "Cloning Flycast (dev branch, very slow)..."
	git clone --depth=1 --single-branch --recursive https://github.com/flyinghead/flycast.git -b dev "${FLYCAST_DIR}"
	kosaio-echo "Flycast has been cloned."
}

function build() {
	kosaio-echo "Re/Building Flycast..."
	cd "${FLYCAST_DIR}"
	mkdir -p build
	cd build
	cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_GDB_SERVER=ON ..
	make -j$(nproc)
	kosaio-echo "Flycast has been built."
}

function update() {
	kosaio-echo "Checking for Flycast updates..."
	kosaio-git-common-update "${FLYCAST_DIR}"
	cd "${FLYCAST_DIR}"
	git submodule update --init --recursive
	kosaio-echo "Flycast updated."
}

function install() {
	kosaio-echo "Installing Flycast..."
	dependencies
	clone
	build
	copy-bin
	kosaio-echo "Flycast installation complete.\n " \
		"You can find the executable in ${FLYCAST_BIN_PATH}\n " \
		"If build failed you can post a issue in flycast github.\n " \
		"Remember to provide the necessary BIOS files in the host OS."
}

function uninstall() {
	kosaio-echo "Uninstalling Flycast..."
	rm -rf "${FLYCAST_DIR}"
	rm -f "${FLYCAST_BIN_PATH}"
	kosaio-echo "Flycast uninstallation complete.\n " \
		"Note: Any APT packages installed for Flycast were not removed."
}
