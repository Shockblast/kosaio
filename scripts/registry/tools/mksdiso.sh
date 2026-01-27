#!/bin/bash
set -Eeuo pipefail

# scripts/registry/sdk/mksdiso.sh
# Manifest for mksdiso (SD Card Image Tool)

ID="mksdiso"
NAME="mksdiso"
DESC="Create SD card images for Dreamcast Serial Port adapters"
TAGS="images,sd,serial,iso"
TYPE="tool"
DEPS="build-essential git p7zip-full genisoimage wodim"

function reg_check_health() {
	local tool_dir=$(kosaio_get_tool_dir "mksdiso")
	[ -d "$tool_dir" ] || return 1
	[ -x "$(which mksdiso 2>/dev/null)" ] || [ -f "${DREAMCAST_BIN_PATH}/mksdiso" ] || return 2
	return 0
}

function reg_clone() {
	local tool_dir=$(kosaio_get_tool_dir "mksdiso")
	log_info --draw-line "Cloning mksdiso repository..."
	kosaio_git_clone "https://github.com/Nold360/mksdiso.git" "${tool_dir}"
}

function reg_build() {
	local tool_dir=$(kosaio_get_tool_dir "mksdiso")
	[ -d "$tool_dir" ] || { log_error "Source code missing."; return 1; }
	log_info --draw-line "mksdiso is a script-based tool, nothing to compile."
}

function reg_apply() {
	local tool_dir=$(kosaio_get_tool_dir "mksdiso")
	[ -d "$tool_dir" ] || return 1

	log_info --draw-line "Installing mksdiso..."
	# Use the provided Makefile for standard installation
	(cd "${tool_dir}" && PREFIX="${DREAMCAST_SDK}" make install)
	log_success "mksdiso applied successfully."
}

function reg_install() {
	reg_clone
	reg_build
	reg_apply
	log_success "mksdiso installation complete."
}

function reg_uninstall() {
	local tool_dir=$(kosaio_get_tool_dir "mksdiso")
	if [ -d "$tool_dir" ]; then
		(cd "${tool_dir}" && make uninstall || true)
		rm -rf "$tool_dir"
	fi
	rm -f "${DREAMCAST_BIN_PATH}/mksdiso"
	log_success "mksdiso removed."
}

function reg_update() {
	local tool_dir=$(kosaio_get_tool_dir "mksdiso")
	kosaio_standard_update_flow "mksdiso" "mksdiso" "$tool_dir" "$@"
}
