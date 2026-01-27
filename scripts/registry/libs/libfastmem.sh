#!/bin/bash
# scripts/registry/libs/libfastmem.sh
# Manifest for libfastmem (Optimized memory routines for Dreamcast)

ID="libfastmem"
NAME="libfastmem"
DESC="Memory management and performance optimization library (fast memcpy/memset)"
TAGS="lib,memory,performance,optimization"
TYPE="lib"
DEPS="build-essential git"

function reg_check_health() {
	local tool_dir=$(kosaio_get_tool_dir "$ID")
	[ -d "$tool_dir" ] || return 1
	
	# libfastmem Makefile (via Makefile.prefab) installs to addons/
	[ -f "${KOS_BASE}/addons/lib/dreamcast/libfastmem.a" ] || return 2
	[ -d "${KOS_BASE}/addons/include/fastmem" ] || return 2
	return 0
}

function reg_clone() {
	local tool_dir=$(kosaio_get_tool_dir "$ID")
	log_info --draw-line "Cloning libfastmem..."
	kosaio_git_clone "https://github.com/sega-dreamcast/libfastmem.git" "${tool_dir}"
}

function reg_build() {
	local tool_dir=$(kosaio_get_tool_dir "$ID")
	[ -d "$tool_dir" ] || { log_error "Source missing."; return 1; }

	log_info --draw-line "Building libfastmem..."
	
	# We need KOS environment to build
	(cd "${tool_dir}" && source "${KOS_BASE}/environ.sh" && make clean && make)
}

function reg_apply() {
	local tool_dir=$(kosaio_get_tool_dir "$ID")
	log_info "Installing libfastmem headers and library to KOS addons..."
	
	# Ensure directory exists
	mkdir -p "${KOS_BASE}/addons/include/fastmem"
	mkdir -p "${KOS_BASE}/addons/lib/dreamcast"

	# Install Headers
	cp -v "${tool_dir}/include/"*.h "${KOS_BASE}/addons/include/fastmem/"
	
	# Install Library (if not already there by Makefile)
	if [ -f "${tool_dir}/libfastmem.a" ]; then
		cp -v "${tool_dir}/libfastmem.a" "${KOS_BASE}/addons/lib/dreamcast/"
	fi
	
	log_success "libfastmem integrated complete (KOS addons)."
}

function reg_install() {
	reg_clone
	reg_build
	reg_apply
}

function reg_uninstall() {
	local tool_dir=$(kosaio_get_tool_dir "$ID")
	log_info "Uninstalling libfastmem..."
	
	rm -rf "${KOS_BASE}/addons/include/fastmem"
	rm -f "${KOS_BASE}/addons/lib/dreamcast/libfastmem.a"
	rm -rf "$tool_dir"
	
	log_success "libfastmem removed."
}

function reg_update() {
	local tool_dir=$(kosaio_get_tool_dir "$ID")
	kosaio_standard_update_flow "$ID" "$NAME" "$tool_dir" "$@"
}

function reg_clean() {
	local tool_dir=$(kosaio_get_tool_dir "$ID")
	(cd "${tool_dir}" && make clean)
}
