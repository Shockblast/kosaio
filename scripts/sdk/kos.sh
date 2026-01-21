#!/bin/bash
set -e

if [ "$KOSAIO_DEV_MODE" == "1" ]; then
	KOS_DIR="${PROJECTS_DIR}/kosaio-dev/kos"
else
	KOS_DIR="${DREAMCAST_SDK}/kos"
fi
DCCHAIN_DIR="${KOS_DIR}/utils/dc-chain"

# Public functions

function info() {
	kosaio_echo "Name: KallistiOS (KOS) \n" \
		"Git: https://github.com/KallistiOS/KallistiOS.git \n" \
		"Description: KOS is the main open-source SDK for the Dreamcast, providing core libraries and more. \n" \
		"Note: The 'build' and 'update' commands can be very time-consuming."
}

function clone() {
	kosaio_echo "Cloning KOS..."
	kosaio_git_clone --recursive -b v2.2.x https://github.com/KallistiOS/KallistiOS.git "${KOS_DIR}"
	kosaio_echo "KOS has been cloned."
}

function build() {
	__is_installed
	__check_requeriments
	kosaio_echo "Build KOS..."

	# Copy dc-chain settings
	echo "Note: Copy Makefile.cfg to ${DCCHAIN_DIR}"

	if [ -f "${DCCHAIN_DIR}/Makefile.cfg" ]; then
		echo "Note: Makefile.cfg file found in ${DCCHAIN_DIR}." >&2
	else
		cp "${KOSAIO_DIR}/dc-chain-settings/Makefile.cfg" "${DCCHAIN_DIR}"

		if [ -f "${DCCHAIN_DIR}/Makefile.cfg" ]; then
			echo "Note: Copied Makefile.cfg to ${DCCHAIN_DIR}."
		else
			echo "Error: Cant copy Makefile.cfg, check permissions."
			exit 1
		fi
	fi

	# Build dc-chain
	cd "${DCCHAIN_DIR}"
	make -j$(nproc)
	make clean

	# Setup environment (required for building KOS itself)
	__setup_environ

	# Build kos
	source "${DREAMCAST_SDK}/kos/environ.sh"
	cd "${KOS_DIR}" # KOS_DIR is dynamic based on dev mode
	make -j$(nproc)

	kosaio_echo "KOS builds."
}

function update() {
	__is_installed
	__check_requeriments
	kosaio_echo "Checking for KOS updates..."
	kosaio_git_common_update "${KOS_DIR}"
	cd "${KOS_DIR}"
	git submodule update --init --recursive
	# Update logic might need rebuild, keeping previous message
	kosaio_echo "KOS updated, now you can run 'kosaio install kos' to rebuild.\n" \
		"Warning: This will require a full rebuild."
}

function install() {
	__check_requeriments
	kosaio_echo "Installing KOS..."
	clone
	build
	apply
	kosaio_echo "KOS Installed."
}

function diagnose() {
	kosaio_echo "Diagnosing KallistiOS (KOS)..."
	local errors=0
	
	# 1. Directory presence
	if [ -d "${KOS_DIR}" ]; then
		kosaio_print_status "PASS" "KOS directory found at ${KOS_DIR}"
	else
		kosaio_print_status "FAIL" "KOS directory MISSING."
		((errors++))
	fi

	# 2. Environment script
	if [ -f "${DREAMCAST_SDK}/kos/environ.sh" ]; then
		kosaio_print_status "PASS" "environ.sh found."
	else
		kosaio_print_status "FAIL" "environ.sh MISSING (Run 'kosaio build kos' or 'install kos')."
		((errors++))
	fi

	# 3. Compiled library
	local lib_path="${KOS_DIR}/lib/dreamcast/libkallisti.a"
	if [ -f "$lib_path" ]; then
		kosaio_print_status "PASS" "Compiled library found: libkallisti.a"
	else
		kosaio_print_status "FAIL" "libkallisti.a NOT FOUND. KOS might not be compiled."
		((errors++))
	fi

	if [ "$errors" -eq 0 ]; then
		echo ""
		kosaio_print_status "INFO" "KOS looks healthy!"
		return 0
	else
		echo ""
		kosaio_print_status "FAIL" "KOS has issues. Please run 'kosaio install kos' to fix."
		return 1
	fi
}

function apply() {
	__is_installed
	__check_requeriments
	__setup_environ
}

function uninstall() {
	__is_installed

	# Check for dependent ports by looking for their typical install locations or source folders
	# This is a best-effort check.
	
	if [ -d "${DREAMCAST_SDK}/kos-ports" ]; then
		kosaio_echo "Warning: KOS-PORTS detected. Uninstallation might break it."
	fi

	if [ -f "${DREAMCAST_SDK}/kos/addons/lib/dreamcast/libGLdc.a" ]; then
		kosaio_echo "Warning: GLdc library detected."
	fi

	if [ -f "${DREAMCAST_SDK}/kos/addons/lib/dreamcast/libaldc.a" ]; then
		kosaio_echo "Warning: ALdc library detected."
	fi

	# dcload-ip/serial are usually standalone binaries in bin, but rely on KOS to be built.
	# Running them doesn't strictly require KOS source, but rebuilding them does.
	if [ -f "${DREAMCAST_BIN_PATH}/dc-tool-ip" ]; then
		kosaio_echo "Warning: dcload-ip detected. You won't be able to rebuild it without KOS."
	fi

	kosaio_echo "Uninstalling KOS..."
	rm -rf "${KOS_DIR}"

	# Restore .bashrc from backup
	if [ -f "/root/.bashrc_og" ]; then
		rm -f "/root/.bashrc"
		cp "/root/.bashrc_og" "/root/.bashrc"
	fi

	kosaio_echo "KOS Uninstalled."
}

# Private functions

function __check_requeriments() {
	# Crudini removed from requirements
	kosaio_require_packages bison build-essential bzip2 cmake curl diffutils flex gawk gettext git \
		libelf-dev libgmp-dev libisofs-dev libjpeg-dev libmpc-dev libmpfr-dev libpng-dev \
		make meson ninja-build patch pkg-config python3 rake sed tar texinfo wget
}

function __is_installed() {
	if [ ! -d "${KOS_DIR}" ]; then
		kosaio_echo "KOS is not installed (directory missing)."
		exit 1
	fi
}

function __setup_environ() {
	# Check file and Backup .bashrc
	if [ ! -f "/root/.bashrc" ]; then
		echo "Error: /root/.bashrc file not found, this file is required." >&2
		exit 1
	fi

	if [ ! -f "/root/.bashrc_og" ]; then
		# Create Backup
		cp "/root/.bashrc" "/root/.bashrc_og"
		echo "Note: Created backup of /root/.bashrc as /root/.bashrc_og"
	fi

	# Copy kos env, this replace the older in case of update
	mkdir -p "${DREAMCAST_SDK}/kos"
	if [ -f "${KOS_DIR}/doc/environ.sh.sample" ]; then
		cp "${KOS_DIR}/doc/environ.sh.sample" "${DREAMCAST_SDK}/kos/environ.sh"
		echo "Note: Copied environ.sh to ${DREAMCAST_SDK}/kos."

		# Update KOS_BASE to match the actual installation directory (critical for --dev mode)
		sed -i "s|export KOS_BASE=.*|export KOS_BASE=\"${KOS_DIR}\"|g" "${DREAMCAST_SDK}/kos/environ.sh"
		# Also uncomment it if it's commented out in the sample
		sed -i "s|# export KOS_BASE=|export KOS_BASE=|g" "${DREAMCAST_SDK}/kos/environ.sh"
	else
		echo "Error: KOS sample environment file not found at ${KOS_DIR}/doc/environ.sh.sample" >&2
		exit 1
	fi

	# Include kos env to .bashrc if not already there
	local source_line="source ${DREAMCAST_SDK}/kos/environ.sh"
	if ! grep -Fxq "${source_line}" /root/.bashrc; then
		echo "${source_line}" >>/root/.bashrc
		echo "Note: Added source line to /root/.bashrc"
	else
		echo "Note: Source line already exists in /root/.bashrc"
	fi
}
