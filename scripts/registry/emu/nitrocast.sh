#!/bin/bash
set -Eeuo pipefail

# scripts/registry/emu/nitrocast.sh
# Manifest for Nitrocast (Fast Emulator)

ID="nitrocast"
NAME="nitrocast"
DESC="Modern, fast Dreamcast emulator (Nitro version)"
TAGS="emulator,testing,graphics,vulkan"
TYPE="emulator"
DEPS="libgtk-3-dev libopenal-dev libpng-dev libgl1-mesa-dev zlib1g-dev meson ninja-build git build-essential"

function reg_check_health() {
	local tool_dir=$(kosaio_get_tool_dir "nitrocast")
	[ -d "$tool_dir" ] || return 1
	[ -f "${PROJECTS_DIR}/nitrocast" ] || return 2
	return 0
}

function reg_info() {
	log_box --info "NITROCAST: HIGH PRECISION" \
		"${C_YELLOW}Context:${C_RESET} Specialized Dreamcast emulator for debugging & testing." \
		"${C_YELLOW}Build System:${C_RESET} Uses ${C_CYAN}Meson + Ninja${C_RESET} (Modern/Fast)." \
		"${C_YELLOW}Reqs:${C_RESET} Requires ${C_MAGENTA}GTK3${C_RESET} for the user interface." \
		"${C_YELLOW}Note:${C_RESET} Excellent for homebrew development due to accuracy." \
		"${C_RED}Warning:${C_RESET} GUI glitches possible if launched from terminal."
}

function reg_clone() {
	local tool_dir=$(kosaio_get_tool_dir "nitrocast")
	log_info --draw-line "Cloning nitrocast repository..."
	kosaio_git_clone --recursive https://gitlab.com/simulant/community/lxdream-nitro.git "${tool_dir}"
}

function reg_build() {
	local tool_dir=$(kosaio_get_tool_dir "nitrocast")
	[ -d "$tool_dir" ] || { log_error "Source code missing."; return 1; }

	log_info --draw-line "Re-building nitrocast..."
	cd "${tool_dir}"
	rm -rf build && mkdir build
	meson setup build && meson compile -C build
}

function reg_apply() {
	local tool_dir=$(kosaio_get_tool_dir "nitrocast")
	local bin_sh="${tool_dir}/build/nitrocast"

	if [ ! -f "$bin_sh" ]; then
		log_error "nitrocast build not found."
		return 1
	else
		log_info "nitrocast build found. execute export function!"
		reg_export
	fi
}

function reg_export() {
	local tool_dir=$(kosaio_get_tool_dir "$ID")
	local host_out="${KOSAIO_DIR}/out/${ID}"
	local bin_sh="${tool_dir}/build/nitrocast"

	log_info "Exporting ${NAME} to host..."

	if [ ! -f "$bin_sh" ]; then
		log_error "nitrocast build not found. Run 'kosaio build ${ID}' first."
		return 1
	fi

	mkdir -p "${host_out}"
	cp -v "$bin_sh" "${host_out}/"
	log_success "Export complete: ${host_out}/nitrocast"
}

function reg_install() {
	reg_clone
	reg_build
	reg_apply
	log_success "nitrocast installation complete."
}

function reg_uninstall() {
	local tool_dir=$(kosaio_get_tool_dir "nitrocast")
	rm -rf "$tool_dir"
	rm -f "${PROJECTS_DIR}/nitrocast"
	log_success "nitrocast removed."
}

function reg_update() {
	local tool_dir=$(kosaio_get_tool_dir "nitrocast")
	kosaio_standard_update_flow "nitrocast" "nitrocast" "$tool_dir" "$@"
}
