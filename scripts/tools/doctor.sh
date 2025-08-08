#!/bin/bash
set -e

function check_dependencies() {
	apt-get install -y git nano vim ca-certificates crudini
	kosaio_echo "KOSAIO DEPENDENCIES"
}

function check_required_vars() {
	local SDK_DIR_LIST=(
		"DREAMCAST_SDK_EXTRAS"
		"DREAMCAST_SDK"
		"PROJECTS_DIR"
		"DREAMCAST_BIN_PATH"
		"KOSAIO_DIR"
		"KOSAIO_CONFIG"
		"KOS_BASE"
		"KOS_PORTS"
		"DC_TOOLS_BASE"
	)

	for var_name in "${SDK_DIR_LIST[@]}"; do
		if [ -z "${!var_name}" ]; then
			echo "Error: ${var_name} is not set. Please set it appropriately." >&2
			exit 1
		else
			echo -e "${var_name} - OK \n"
		fi
	done

	kosaio_echo "ENV VARS CHECK."
}

function check_folder_permission() {
	kosaio_set_folder_permission \
		"${DREAMCAST_SDK_EXTRAS}" \
		"${DREAMCAST_SDK}" \
		"${PROJECTS_DIR}" \
		"${DREAMCAST_BIN_PATH}" \
		"${KOSAIO_DIR}" \
		"${KOS_BASE}" \
		"${KOS_PORTS}" \
		"${DC_TOOLS_BASE}"

	kosaio_echo "SDK FOLDER PERMISSION CHECK."
}

function check_git_settings() {
	git config --global pull.rebase true
	git config --global core.fileMode false
	kosaio_echo "GIT CONFIG SET"
}

function install_all_dependencies() {
	apt-get install -y \
		bison build-essential bzip2 ca-certificates cmake curl \
		diffutils flex gawk genisoimage gettext git \
		libcurl4-openssl-dev libelf-dev libgmp-dev libisofs libisofs-dev libjpeg-dev \
		libmpc-dev libmpfr-dev libpng-dev libsdl2-dev libvulkan-dev make meson \
		nano ninja-build p7zip patch pkg-config python3 \
		rake sed tar texinfo vim wget \
		wodim crudini

	kosaio_echo "ALL DEPENDENCIES INSTALLED."
}
