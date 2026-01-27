#!/bin/bash
set -Eeuo pipefail

# scripts/registry/sdk/makeip.sh
# Manifest for makeip (IP.BIN Generator)

ID="makeip"
NAME="makeip"
DESC="Tool to generate IP.BIN files for bootable Dreamcast discs"
TAGS="boot,ip.bin,disc,binary"
TYPE="tool"
DEPS="build-essential git"

function reg_check_health() {
	local tool_dir=$(kosaio_get_tool_dir "makeip")
	[ -d "$tool_dir" ] || return 1
	[ -f "${DREAMCAST_BIN_PATH}/makeip" ] || return 2
	return 0
}

function reg_clone() {
	local tool_dir=$(kosaio_get_tool_dir "makeip")
	log_info --draw-line "Cloning makeip..."
	kosaio_git_clone https://github.com/Dreamcast-Projects/makeip.git "${tool_dir}"
}

function reg_build() {
	local tool_dir=$(kosaio_get_tool_dir "makeip")
	log_info --draw-line "Building makeip..."
	(cd "${tool_dir}/src" && make)
}

function reg_apply() {
	local tool_dir=$(kosaio_get_tool_dir "makeip")
	cp "${tool_dir}/src/makeip" "${DREAMCAST_BIN_PATH}/"
	log_success "makeip installed."
}

function reg_install() {
	reg_clone
	reg_build
	reg_apply
}

function reg_uninstall() {
	local tool_dir=$(kosaio_get_tool_dir "makeip")
	rm -rf "$tool_dir"
	rm -f "${DREAMCAST_BIN_PATH}/makeip"
}

function reg_update() {
	local tool_dir=$(kosaio_get_tool_dir "makeip")
	kosaio_standard_update_flow "makeip" "makeip" "$tool_dir" "$@"
}
