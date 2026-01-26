#!/bin/bash
set -Eeuo pipefail

# scripts/registry/sdk/img4dc.sh
# Manifest for img4dc (CDI/GDI tools)

ID="img4dc"
NAME="img4dc"
DESC="Tools for generating Dreamcast disc images (cdi-brenner, gdi-utils)"
TAGS="disc,images,cdi,gdi"
TYPE="tool"
DEPS="build-essential git cmake libelf-dev"

function reg_check_health() {
	local tool_dir=$(kosaio_get_tool_dir "img4dc")
	[ -d "$tool_dir" ] || return 1
	[ -f "${DREAMCAST_BIN_PATH}/cdi4dc" ] || return 2
	return 0
}

function reg_clone() {
	local tool_dir=$(kosaio_get_tool_dir "img4dc")
	log_info --draw-line "Cloning img4dc repository..."
	# Using the more prevalent fork
	kosaio_git_clone "https://github.com/mrneo240/img4dc.git" "${tool_dir}"
}

function reg_build() {
	local tool_dir=$(kosaio_get_tool_dir "img4dc")
	[ -d "$tool_dir" ] || { log_error "Source code missing."; return 1; }

	log_info --draw-line "Building img4dc..."
	mkdir -p "${tool_dir}/build"
	(cd "${tool_dir}/build" && cmake .. && make -j$(nproc))
}

function reg_apply() {
	local tool_dir=$(kosaio_get_tool_dir "img4dc")
	local build_dir="${tool_dir}/build"

	mkdir -p "${DREAMCAST_BIN_PATH}"
	# Check multiple possible binary locations (some forks differ)
	if [ -f "${build_dir}/cdi4dc/cdi4dc" ]; then
		cp "${build_dir}/cdi4dc/cdi4dc" "${DREAMCAST_BIN_PATH}/"
		[ -f "${build_dir}/gdi4dc/gdi4dc" ] && cp "${build_dir}/gdi4dc/gdi4dc" "${DREAMCAST_BIN_PATH}/"
	elif [ -f "${build_dir}/cdi4dc" ]; then
		cp "${build_dir}/cdi4dc" "${DREAMCAST_BIN_PATH}/"
	fi

	log_success "img4dc binaries installed to ${DREAMCAST_BIN_PATH}"
}

function reg_install() {
	reg_clone
	reg_build
	reg_apply
	log_success "img4dc installation complete."
}

function reg_uninstall() {
	local tool_dir=$(kosaio_get_tool_dir "img4dc")
	rm -rf "$tool_dir"
	rm -f "${DREAMCAST_BIN_PATH}/cdi4dc"
	rm -f "${DREAMCAST_BIN_PATH}/gdi4dc"
	rm -f "${DREAMCAST_BIN_PATH}/mds4dc"
	log_success "img4dc removed."
}

function reg_update() {
	local tool_dir=$(kosaio_get_tool_dir "img4dc")
	kosaio_git_common_update "$tool_dir"
	log_info "Building img4dc..."
}
function reg_clean() {
	local tool_dir=$(kosaio_get_tool_dir "img4dc")
	[ -d "${tool_dir}/build" ] || return 0
	log_info --draw-line "Cleaning img4dc build directory..."
	rm -rf "${tool_dir}/build"
	log_success "img4dc build directory removed."
}
