#!/bin/bash
set -Eeuo pipefail

# scripts/registry/sdk/lxdream-nitro.sh
# Manifest for lxdream-nitro (Fast Emulator)

ID="lxdream-nitro"
NAME="lxdream-nitro"
DESC="Modern, fast Dreamcast emulator (Nitro version)"
TAGS="emulator,testing,graphics,vulkan"
TYPE="emulator"
DEPS="libgtk-3-dev meson ninja-build git build-essential"

function reg_check_health() {
	local tool_dir=$(kosaio_get_tool_dir "lxdream-nitro")
	[ -d "$tool_dir" ] || return 1
	[ -f "${PROJECTS_DIR}/lxdream-nitro" ] || return 2
	return 0
}

function reg_clone() {
	local tool_dir=$(kosaio_get_tool_dir "lxdream-nitro")
	log_info --draw-line "Cloning lxdream-nitro repository..."
	kosaio_git_clone --recursive https://gitlab.com/simulant/community/lxdream-nitro.git "${tool_dir}"
}

function reg_build() {
	local tool_dir=$(kosaio_get_tool_dir "lxdream-nitro")
	[ -d "$tool_dir" ] || { log_error "Source code missing."; return 1; }

	log_info --draw-line "Re-building lxdream-nitro..."
	cd "${tool_dir}"
	rm -rf build && mkdir build
	meson setup build && meson compile -C build
}

function reg_apply() {
	local tool_dir=$(kosaio_get_tool_dir "lxdream-nitro")
	local bin_sh="${tool_dir}/build/lxdream-nitro"

	if [ ! -f "$bin_sh" ]; then
		log_error "lxdream-nitro build not found."
		return 1
	fi

	cp "$bin_sh" "${PROJECTS_DIR}/"
	log_success "lxdream-nitro deployed to ${PROJECTS_DIR}/"
}

function reg_install() {
	reg_clone
	reg_build
	reg_apply
	log_success "lxdream-nitro installation complete."
}

function reg_uninstall() {
	local tool_dir=$(kosaio_get_tool_dir "lxdream-nitro")
	rm -rf "$tool_dir"
	rm -f "${PROJECTS_DIR}/lxdream-nitro"
	log_success "lxdream-nitro removed."
}

function reg_update() {
	local tool_dir=$(kosaio_get_tool_dir "lxdream-nitro")
	kosaio_standard_update_flow "lxdream-nitro" "lxdream-nitro" "$tool_dir" "$@"
}
