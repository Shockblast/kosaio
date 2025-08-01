#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

KOS_DIR="${DREAMCAST_SDK}/kos"
KOS_PORTS_DIR="${DREAMCAST_SDK}/kos-ports"
DCCHAIN_DIR="${DREAMCAST_SDK}/kos/utils/dc-chain"

function info() {
	kosaio-echo "Name: KallistiOS (KOS) and KOS-Ports \n" \
		"Git (KOS): https://github.com/KallistiOS/KallistiOS.git \n" \
		"Git (KOS-Ports): https://github.com/KallistiOS/kos-ports \n" \
		"Description: KOS is the main open-source SDK for the Dreamcast, providing core libraries and a kernel. KOS-Ports is a collection of third-party libraries ported to work with KOS, simplifying development by providing common tools for graphics, sound, and more.\n" \
		"Note-1: KOS and KOS-Ports are the foundation of this environment and come pre-installed. \n" \
		"Note-2: The 'build' and 'update' commands can be very time-consuming."
}

function dependencies() {
	kosaio-echo "Installing KOS and KOS-PORTS dependencies..."

	apt-get install -y --no-install-recommends \
		bison build-essential bzip2 cmake curl diffutils flex gawk gettext git \
		libelf-dev libgmp-dev libisofs-dev libjpeg-dev libmpc-dev libmpfr-dev libpng-dev \
		make meson ninja-build patch pkg-config python3 rake sed tar texinfo wget

	kosaio-echo "KOS and KOS-PORTS dependencies installed..."
}

function copy-bin() {
	kosaio-echo "Nothing to copy..."
}

function clone() {
	kosaio-echo "Cloning KOS and KOS-PORTS..."
	git clone --depth=1 --single-branch --recursive https://github.com/KallistiOS/KallistiOS.git "${KOS_DIR}"
	git clone --depth=1 --single-branch --recursive https://github.com/KallistiOS/kos-ports "${KOS_PORTS_DIR}"
	kosaio-echo "KOS and KOS-PORTS has been cloned."
}

# dc-chain compile
function build-dc-chain() {
	cd "${DCCHAIN_DIR}"
	make -j$(nproc) || true
	make clean
}

## KallistiOS (KOS) build, is the main open-source development kit for the Sega Dreamcast.
## It provides the core libraries and kernel to interact with the console's hardware.
function build-kos() {
	cd "${KOS_DIR}"
	make -j$(nproc) || true
}

## KOS-Ports build, is a collection of third-party libraries ported to work with KallistiOS.
## This includes common libraries for graphics, sound, file systems, and more, simplifying development.
function build-kos-ports() {
	cd "${KOS_PORTS_DIR}/utils"
	./build-all.sh || true
}

function build() {
	kosaio-echo "Build KOS and KOS-PORTS..."
	build-dc-chain
	build-kos
	build-kos-ports
	kosaio-echo "KOS and KOS-PORTS builds."
}

function update() {
	kosaio-echo "Checking for KOS and KOS-PORTS updates..."
	kosaio-git-common-update "${KOS_DIR}"
	cd "${KOS_DIR}"
	git submodule update --init --recursive
	kosaio-git-common-update "${KOS_PORTS_DIR}"
	cd "${KOS_PORTS_DIR}"
	git submodule update --init --recursive
	kosaio-echo "KOS and KOS-PORTS updated, now you can run 'kosaio kos build'.\n" \
		"And now you can get up and go for coffee, this will take a while."
}

function install() {
	kosaio-echo "KOS and KOS-PORTS is already installed (by default)..."
}

function uninstall() {
	kosaio-echo "KOS and KOS-PORTS cant be uninstalled..."
}
