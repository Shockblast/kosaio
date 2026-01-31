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

	local gdb_state="OFF"
	for arg in "$@"; do
		if [[ "$arg" == "--with-gdb" ]]; then
			gdb_state="ON"
		fi
	done

	log_info --draw-line "Compiling Flycast (GDB Server: ${gdb_state})..."
	
	rm -rf "${tool_dir}/build"
	mkdir -p "${tool_dir}/build"
	# Configure CMake with GDB state
	(cd "${tool_dir}/build" && cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_GDB_SERVER=${gdb_state} .. && make -j$(nproc))
}

function reg_info() {
	log_box --info "FLYCAST: EXTRA INFORMATION" \
		"${C_CYAN}--with-gdb${C_RESET}     : Enable built-in GDB Server (Required for debugging)"
}

function reg_apply() {
	local tool_dir=$(kosaio_get_tool_dir "flycast")

	if [ ! -f "${tool_dir}/build/flycast" ]; then
		log_error "Flycast binary not found. Build it first."
		return 1
	else
		log_info "Flycast binary found. execute export function!."
		reg_export
	fi
}

function reg_export() {
	local tool_dir=$(kosaio_get_tool_dir "$ID")
	local host_out="${KOSAIO_DIR}/out/${ID}"

	log_info "Exporting ${NAME} to host..."

	if [ ! -f "${tool_dir}/build/flycast" ]; then
		log_error "Flycast binary not found. Run 'kosaio build ${ID}' first."
		return 1
	fi

	mkdir -p "${host_out}"
	cp -v "${tool_dir}/build/flycast" "${host_out}/"
	log_success "Export complete: ${host_out}/flycast"
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
