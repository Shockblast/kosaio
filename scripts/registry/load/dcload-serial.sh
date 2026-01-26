#!/bin/bash
set -Eeuo pipefail

# scripts/registry/sdk/dcload-serial.sh
# Manifest for dcload-serial (Serial Port Loader)

ID="dcload-serial"
NAME="dcload-serial"
DESC="Dreamcast Serial loader and debug tool"
TAGS="loader,serial,debug"
TYPE="loader"
DEPS="build-essential git libelf-dev"

function reg_check_health() {
	local tool_dir=$(kosaio_get_tool_dir "dcload-serial")
	[ -d "$tool_dir" ] || return 1
	[ -f "${DREAMCAST_BIN_PATH}/dc-tool-ser" ] || return 2
	return 0
}

function reg_clone() {
	local tool_dir=$(kosaio_get_tool_dir "dcload-serial")
	log_info --draw-line "Cloning dcload-serial..."
	kosaio_git_clone https://github.com/KallistiOS/dcload-serial.git "${tool_dir}"
}

function reg_install() {
	reg_clone
	reg_build
	reg_apply
}

function reg_build() {
	local tool_dir=$(kosaio_get_tool_dir "dcload-serial")
	log_info --draw-line "Building dcload-serial host tool..."
	(cd "${tool_dir}/host-src/tool" && make)
}

function reg_apply() {
	local tool_dir=$(kosaio_get_tool_dir "dcload-serial")
	mkdir -p "${DREAMCAST_BIN_PATH}"
	cp "${tool_dir}/host-src/tool/dc-tool-ser" "${DREAMCAST_BIN_PATH}/"
	log_success "dc-tool-ser installed."
}

function reg_uninstall() {
	local tool_dir=$(kosaio_get_tool_dir "dcload-serial")
	rm -rf "$tool_dir"
	rm -f "${DREAMCAST_BIN_PATH}/dc-tool-ser"
}

function reg_update() {
	local tool_dir=$(kosaio_get_tool_dir "dcload-serial")
	kosaio_git_common_update "$tool_dir"
	log_info "Building dcload-serial host tool..."
}
