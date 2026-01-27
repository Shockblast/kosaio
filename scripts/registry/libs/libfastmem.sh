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
	
	# Fix: libfastmem Makefile expects ../include to exist for the symlink it creates
	mkdir -p "$(dirname "$tool_dir")/include"

	# We need KOS environment to build
	(cd "${tool_dir}" && source "${KOS_BASE}/environ.sh" && make clean && make)
}

function reg_apply() {
	# NOTE: The 'make' command in reg_build already installs the .a to addons/lib/dreamcast
	# and the symlink in reg_build handled the include.
	# But to be safe and consistent with KOSAIO registry, we ensure the headers are properly placed.
	
	local tool_dir=$(kosaio_get_tool_dir "$ID")
	log_info "Ensuring libfastmem headers are in KOS addons..."
	
	mkdir -p "${KOS_BASE}/addons/include/fastmem"
	cp -v "${tool_dir}/include/fastmem.h" "${KOS_BASE}/addons/include/fastmem/"
	
	log_success "libfastmem integration complete (KOS addons)."
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
