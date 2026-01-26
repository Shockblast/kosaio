#!/bin/bash
set -Eeuo pipefail

# scripts/registry/sdk/mkdcdisc.sh
# Manifest for mkdcdisc (Self-booting CDI images)

ID="mkdcdisc"
NAME="mkdcdisc"
DESC="Create self-booting CDI disc images for Dreamcast"
TAGS="images,cdi,disc,iso"
TYPE="tool"
DEPS="git meson build-essential pkg-config libisofs-dev"

function reg_check_health() {
	local tool_dir=$(kosaio_get_tool_dir "mkdcdisc")
	[ -d "$tool_dir" ] || return 1
	[ -f "${DREAMCAST_BIN_PATH}/mkdcdisc" ] || return 2
	return 0
}

function reg_clone() {
	local tool_dir=$(kosaio_get_tool_dir "mkdcdisc")
	log_info --draw-line "Cloning mkdcdisc..."
	kosaio_git_clone https://gitlab.com/simulant/mkdcdisc.git "${tool_dir}"
}

function reg_install() {
	reg_clone
	reg_build
	reg_apply
}

function reg_build() {
	local tool_dir=$(kosaio_get_tool_dir "mkdcdisc")
	log_info --draw-line "Building mkdcdisc..."
	(cd "${tool_dir}" && meson setup builddir && meson compile -C builddir)
}

function reg_apply() {
	local tool_dir=$(kosaio_get_tool_dir "mkdcdisc")
	mkdir -p "${DREAMCAST_BIN_PATH}"
	cp "${tool_dir}/builddir/mkdcdisc" "${DREAMCAST_BIN_PATH}/"
	log_success "mkdcdisc installed to bin."
}

function reg_uninstall() {
	local tool_dir=$(kosaio_get_tool_dir "mkdcdisc")
	rm -rf "$tool_dir"
	rm -f "${DREAMCAST_BIN_PATH}/mkdcdisc"
	log_success "mkdcdisc removed."
}

function reg_update() {
	local tool_dir=$(kosaio_get_tool_dir "mkdcdisc")
	kosaio_git_common_update "$tool_dir"
	log_info "Building mkdcdisc..."
}
