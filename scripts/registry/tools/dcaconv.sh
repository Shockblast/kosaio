#!/bin/bash
set -Eeuo pipefail

# scripts/registry/sdk/dcaconv.sh
# Manifest for dcaconv (Audio Converter)

ID="dcaconv"
NAME="dcaconv"
DESC="Audio converter for Dreamcast AICA (wav/aica)"
TAGS="audio,converter,aica,wav"
TYPE="tool"
DEPS="build-essential git"

function reg_check_health() {
	local tool_dir=$(kosaio_get_tool_dir "dcaconv")
	[ -d "$tool_dir" ] || return 1
	[ -f "${DREAMCAST_BIN_PATH}/dcaconv" ] || return 2
	return 0
}

function reg_clone() {
	local tool_dir=$(kosaio_get_tool_dir "dcaconv")
	log_info --draw-line "Cloning dcaconv..."
	kosaio_git_clone https://github.com/TapamN/dcaconv.git "${tool_dir}"
}

function reg_build() {
	local tool_dir=$(kosaio_get_tool_dir "dcaconv")
	log_info --draw-line "Building dcaconv..."
	(cd "${tool_dir}" && make)
}

function reg_install() {
	reg_clone
	reg_build
	reg_apply
}

function reg_apply() {
	local tool_dir=$(kosaio_get_tool_dir "dcaconv")
	mkdir -p "${DREAMCAST_BIN_PATH}"
	cp "${tool_dir}/dcaconv" "${DREAMCAST_BIN_PATH}/"
	log_success "dcaconv installed to bin."
}

function reg_uninstall() {
	local tool_dir=$(kosaio_get_tool_dir "dcaconv")
	rm -rf "$tool_dir"
	rm -f "${DREAMCAST_BIN_PATH}/dcaconv"
	log_success "dcaconv removed."
}

function reg_update() {
	local tool_dir=$(kosaio_get_tool_dir "dcaconv")
	kosaio_standard_update_flow "dcaconv" "dcaconv" "$tool_dir" "$@"
}
