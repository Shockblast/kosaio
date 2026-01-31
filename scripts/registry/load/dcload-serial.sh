#!/bin/bash
set -Eeuo pipefail

# scripts/registry/sdk/dcload-serial.sh
# Manifest for dcload-serial (Serial Port Loader)

ID="dcload-serial"
NAME="dcload-serial"
DESC="Dreamcast Serial loader and debug tool"
TAGS="loader,serial,debug"
TYPE="loader"
DEPS="build-essential git libelf-dev"

function reg_check_health() {
	local tool_dir=$(kosaio_get_tool_dir "dcload-serial")
	[ -d "$tool_dir" ] || return 1
	[ -f "${DREAMCAST_BIN_PATH}/dc-tool-ser" ] || return 2
	return 0
}

function reg_info() {
	log_box --info "DCLOAD-SERIAL: CABLE LOADER" \
		"${C_YELLOW}Context:${C_RESET} Code upload via Serial Cable (Coder's Cable/USB)." \
		"${C_YELLOW}Tool:${C_RESET}    dc-tool-ser (Host Utility)" \
		"${C_YELLOW}Usage:${C_RESET}   dc-tool-ser -t <device> -x <binary.elf>"
}

function reg_clone() {
	local tool_dir=$(kosaio_get_tool_dir "dcload-serial")
	log_info --draw-line "Cloning dcload-serial..."
	kosaio_git_clone https://github.com/KallistiOS/dcload-serial.git "${tool_dir}"
}

function reg_install() {
	reg_clone
	reg_build
	reg_apply
}

function reg_build() {
	local tool_dir=$(kosaio_get_tool_dir "dcload-serial")
	log_info --draw-line "Building dcload-serial host tool..."
	(cd "${tool_dir}/host-src/tool" && make)
}

function reg_apply() {
	local tool_dir=$(kosaio_get_tool_dir "dcload-serial")
	mkdir -p "${DREAMCAST_BIN_PATH}"
	cp "${tool_dir}/host-src/tool/dc-tool-ser" "${DREAMCAST_BIN_PATH}/"
	log_success "dc-tool-ser installed."
}

function reg_export() {
	local tool_dir=$(kosaio_get_tool_dir "$ID")
	local host_out="${KOSAIO_DIR}/out/${ID}"
	
	log_info "Exporting ${NAME} to host..."
	
	if [ ! -f "${tool_dir}/host-src/tool/dc-tool-ser" ]; then
		log_error "dc-tool-ser not found. Run 'kosaio build ${ID}' first."
		return 1
	fi
	
	mkdir -p "${host_out}"
	cp -v "${tool_dir}/host-src/tool/dc-tool-ser" "${host_out}/"
	
	log_success "Export complete: ${host_out}/dc-tool-ser"
}

function reg_uninstall() {
	local tool_dir=$(kosaio_get_tool_dir "dcload-serial")
	rm -rf "$tool_dir"
	rm -f "${DREAMCAST_BIN_PATH}/dc-tool-ser"
}

function reg_update() {
	local tool_dir=$(kosaio_get_tool_dir "dcload-serial")
	kosaio_standard_update_flow "dcload-serial" "dcload-serial" "$tool_dir" "$@"
}
