#!/bin/bash
set -e

KOS_DIR="${DREAMCAST_SDK}/kos"
DCCHAIN_DIR="${DREAMCAST_SDK}/kos/utils/dc-chain"

# Public functions

function info() {
	kosaio_echo "Name: KallistiOS (KOS) \n" \
		"Git: https://github.com/KallistiOS/KallistiOS.git \n" \
		"Description: KOS is the main open-source SDK for the Dreamcast, providing core libraries and more. \n" \
		"Note: The 'build' and 'update' commands can be very time-consuming."
}

function clone() {
	kosaio_echo "Cloning KOS..."
	git clone --depth=1 --single-branch --recursive https://github.com/KallistiOS/KallistiOS.git "${KOS_DIR}"
	crudini --set "${KOSAIO_CONFIG}" dreamcast_sdk kos 1
	kosaio_echo "KOS has been cloned."
}

function build() {
	__is_installed
	__check_requeriments
	kosaio_echo "Build KOS..."

	# Copy dc-chain settings
	echo "Note: Copy Makefile.cfg to ${DREAMCAST_SDK}/kos/utils/dc-chain"

	if [ -f "${DREAMCAST_SDK}/kos/utils/dc-chain/Makefile.cfg" ]; then
		echo "Note: Makefile.cfg file found in ${DREAMCAST_SDK}/kos/utils/dc-chain." >&2
	else
		cp "${KOSAIO_DIR}/dc-chain-settings/Makefile.cfg" "${DREAMCAST_SDK}/kos/utils/dc-chain"

		if [ -f "${DREAMCAST_SDK}/kos/utils/dc-chain/Makefile.cfg" ]; then
			echo "Note: Copied Makefile.cfg to ${DREAMCAST_SDK}/kos/utils/dc-chain."
		else
			echo "Error: Cant copy Makefile.cfg, check permissions."
			exit 1
		fi
	fi

	# Build dc-chain
	cd "${DCCHAIN_DIR}"
	make -j$(nproc) || true
	make clean

	# Check file and Backup .bashrc
	if [ ! -f "/root/.bashrc" ]; then
		echo "Error: /root/.bashrc file not found, this file is required." >&2
		exit 1
	else
		# This is for avoid duplicate source kos_enviroment.sh every time execute build
		if [ ! -f "/root/.bashrc_og" ]; then
			# Create Backup
			cp "/root/.bashrc" "/root/.bashrc_og"
		else
			# Restore the fresh backup
			rm -f "/root/.bashrc"
			cp "/root/.bashrc_og" "/root/.bashrc"
		fi
	fi

	# Copy kos env, this replace the older in case of update
	cp "${DREAMCAST_SDK}/kos/doc/environ.sh.sample" "${DREAMCAST_SDK}/kos/environ.sh"

	if [ -f "${DREAMCAST_SDK}/kos/environ.sh" ]; then
		echo "Note: Copied environ.sh to ${DREAMCAST_SDK}/kos."
	else
		echo "Error: Cant copy environ.sh, check permissions."
		exit 1
	fi

	# Include kos env to .bashrc
	echo "source ${DREAMCAST_SDK}/kos/environ.sh" >>/root/.bashrc
	echo "Note: Source environ.sh to .bashrc."

	# Build kos
	source "${DREAMCAST_SDK}/kos/environ.sh"
	cd "${KOS_DIR}"
	make -j$(nproc) || true

	kosaio_echo "KOS builds."
}

function update() {
	__is_installed
	__check_requeriments
	kosaio_echo "Checking for KOS updates..."
	kosaio_git_common_update "${KOS_DIR}"
	cd "${KOS_DIR}"
	git submodule update --init --recursive
	kosaio_echo "KOS updated, now you can run 'kosaio kos build'.\n" \
		"And now you can get up and go for coffee, this will take a while."
}

function install() {
	__check_requeriments
	kosaio_echo "Installing KOS..."
	clone
	build
	apply
	kosaio_echo "KOS Installed."
}

function apply() {
	__is_installed
	__check_requeriments
	kosaio_echo "Nothing to copy..."
}

function uninstall() {
	__is_installed

	local KOS_PORTS=$(crudini --get "${KOSAIO_CONFIG}" dreamcast_sdk kos-ports)
	local GLDC=$(crudini --get "${KOSAIO_CONFIG}" dreamcast_sdk gldc)
	local ALDC=$(crudini --get "${KOSAIO_CONFIG}" dreamcast_sdk aldc)
	local SH4ZAM=$(crudini --get "${KOSAIO_CONFIG}" dreamcast_sdk sh4zam)
	local DCLOADIP=$(crudini --get "${KOSAIO_CONFIG}" dreamcast_sdk dcload-ip)
	local DCLOADSERIAL=$(crudini --get "${KOSAIO_CONFIG}" dreamcast_sdk dcload-serial)

	if [ "${KOS_PORTS}" = "1" ]; then
		kosaio_echo "Warning: You have installed KOS-PORTS, KOS is required to compile/use KOS-PORTS."
	fi

	if [ "${GLDC}" = "1" ]; then
		kosaio_echo "Warning: You have installed GLdc, KOS is required to compile/use GLdc."
	fi

	if [ "${ALDC}" = "1" ]; then
		kosaio_echo "Warning: You have installed ALdc, KOS is required to compile/use ALdc."
	fi

	if [ "${SH4ZAM}" = "1" ]; then
		kosaio_echo "Warning: You have installed Sh4zam, KOS is required to compile/use Sh4zam."
	fi

	if [ "${DCLOADIP}" = "1" ]; then
		kosaio_echo "Warning: You have installed dcload-ip, KOS is required to compile/use dcload-ip."
	fi

	if [ "${DCLOADSERIAL}" = "1" ]; then
		kosaio_echo "Warning: You have installed dcload-serial, KOS is required to compile/use dcload-serial."
	fi

	kosaio_echo "Uninstalling KOS..."
	rm -rf "${KOS_DIR}"

	# Restore .bashrc from backup
	if [ -f "/root/.bashrc_og" ]; then
		rm -f "/root/.bashrc"
		cp "/root/.bashrc_og" "/root/.bashrc"
	fi

	crudini --set "${KOSAIO_CONFIG}" dreamcast_sdk kos 0
	kosaio_echo "KOS Uninstallled."
}

# Private functions

function __check_requeriments() {
	kosaio_require_packages bison build-essential bzip2 cmake curl diffutils flex gawk gettext git \
		libelf-dev libgmp-dev libisofs-dev libjpeg-dev libmpc-dev libmpfr-dev libpng-dev \
		make meson ninja-build patch pkg-config python3 rake sed tar texinfo wget
}

function __is_installed() {
	local IS_INSTALLED=$(crudini --get "${KOSAIO_CONFIG}" dreamcast_sdk kos)

	if [ "${IS_INSTALLED}" = "0" ]; then
		kosaio_echo "KOS is not installled."
		exit 1
	fi

	if [ ! -d "${KOS_DIR}" ]; then
		kosaio_echo "KOS folder not found, is KOS installed?."
		exit 1
	fi
}
