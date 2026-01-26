#!/bin/bash
set -Eeuo pipefail

# scripts/registry/sdk/dcload-ip.sh
# Manifest for dcload-ip (Ethernet Loader)

ID="dcload-ip"
NAME="dcload-ip"
DESC="Dreamcast Ethernet loader and debug tool"
TAGS="loader,ethernet,ip,debug"
TYPE="loader"
DEPS="build-essential git libelf-dev"

function reg_check_health() {
	local tool_dir=$(kosaio_get_tool_dir "dcload-ip")
	[ -d "$tool_dir" ] || return 1
	[ -f "${DREAMCAST_BIN_PATH}/dc-tool-ip" ] || return 2
	return 0
}

function reg_clone() {
	local tool_dir=$(kosaio_get_tool_dir "dcload-ip")
	log_info --draw-line "Cloning dcload-ip..."
	kosaio_git_clone https://github.com/KallistiOS/dcload-ip.git "${tool_dir}"
}

function reg_install() {
	reg_clone
	reg_build
	reg_apply
}

function reg_build() {
	local tool_dir=$(kosaio_get_tool_dir "dcload-ip")
	log_info --draw-line "Building dcload-ip host tool..."
	# Ensure environment for cross-compiling the target if needed, 
	# but here we focus on the host tool dc-tool-ip
	(cd "${tool_dir}/host-src/tool" && make)
}

function reg_apply() {
	local tool_dir=$(kosaio_get_tool_dir "dcload-ip")
	mkdir -p "${DREAMCAST_BIN_PATH}"
	cp "${tool_dir}/host-src/tool/dc-tool-ip" "${DREAMCAST_BIN_PATH}/"
	log_success "dc-tool-ip installed."
}

function reg_uninstall() {
	local tool_dir=$(kosaio_get_tool_dir "dcload-ip")
	rm -rf "$tool_dir"
	rm -f "${DREAMCAST_BIN_PATH}/dc-tool-ip"
}

function reg_update() {
	local tool_dir=$(kosaio_get_tool_dir "dcload-ip")
	kosaio_git_common_update "$tool_dir"
	log_info "Building dcload-ip host tool..."
}
