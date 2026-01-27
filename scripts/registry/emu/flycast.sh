#!/bin/bash
set -Eeuo pipefail

# scripts/registry/sdk/flycast.sh
# Manifest for Flycast Emulator

ID="flycast"
NAME="Flycast"
DESC="High-performance Dreamcast emulator with Vulkan support"
TAGS="emulator,testing,graphics,vulkan,opengl"
TYPE="emulator"
DEPS="libvulkan-dev libsdl2-dev cmake build-essential"

function reg_check_health() {
	local tool_dir=$(kosaio_get_tool_dir "flycast")
	[ -d "$tool_dir" ] || return 1
	[ -f "${PROJECTS_DIR}/flycast/flycast" ] || return 2
	return 0
}

function reg_clone() {
	local tool_dir=$(kosaio_get_tool_dir "flycast")
	log_info --draw-line "Cloning Flycast repository..."
	kosaio_git_clone --recursive https://github.com/flyinghead/flycast.git "${tool_dir}"
}

function reg_build() {
	local tool_dir=$(kosaio_get_tool_dir "flycast")
	[ -d "$tool_dir" ] || { log_error "Flycast source missing. Run 'kosaio clone flycast' first."; return 1; }

	log_info --draw-line "Compiling Flycast (Native build)..."
	mkdir -p "${tool_dir}/build"
	(cd "${tool_dir}/build" && cmake .. && make -j$(nproc))
}

function reg_apply() {
	local tool_dir=$(kosaio_get_tool_dir "flycast")
	local output_dir="${PROJECTS_DIR}/flycast"

	if [ ! -f "${tool_dir}/build/flycast" ]; then
		log_error "Flycast binary not found. Build it first."
		return 1
	fi

	mkdir -p "$output_dir"
	cp "${tool_dir}/build/flycast" "$output_dir/"
	log_success "Flycast binary available at ${output_dir}/flycast"
}

function reg_install() {
	reg_clone
	reg_build
	reg_apply
	log_success "Flycast installation complete."
}

function reg_uninstall() {
	local tool_dir=$(kosaio_get_tool_dir "flycast")
	rm -rf "$tool_dir"
	rm -rf "${PROJECTS_DIR}/flycast"
	log_success "Flycast removed."
}

function reg_update() {
	local tool_dir=$(kosaio_get_tool_dir "flycast")
	kosaio_standard_update_flow "flycast" "Flycast" "$tool_dir" "$@"
}
function reg_clean() {
	local tool_dir=$(kosaio_get_tool_dir "flycast")
	[ -d "${tool_dir}/build" ] || return 0
	log_info --draw-line "Cleaning Flycast build directory..."
	rm -rf "${tool_dir}/build"
	log_success "Flycast build directory removed."
}
