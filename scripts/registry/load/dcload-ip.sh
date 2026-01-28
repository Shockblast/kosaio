#!/bin/bash
set -Eeuo pipefail

# scripts/registry/sdk/dcload-ip.sh
# Manifest for dcload-ip (Ethernet Loader)

ID="dcload-ip"
NAME="dcload-ip"
DESC="Dreamcast Ethernet loader and debug tool"
TAGS="loader,ethernet,ip,debug"
TYPE="loader"
DEPS="build-essential git libelf-dev"

function reg_check_health() {
	local tool_dir=$(kosaio_get_tool_dir "dcload-ip")
	[ -d "$tool_dir" ] || return 1
	[ -f "${DREAMCAST_BIN_PATH}/dc-tool-ip" ] || return 2
	return 0
}

function reg_clone() {
	local tool_dir=$(kosaio_get_tool_dir "dcload-ip")
	log_info --draw-line "Cloning dcload-ip..."
	kosaio_git_clone https://github.com/KallistiOS/dcload-ip.git "${tool_dir}"
}

function reg_install() {
	reg_clone
	reg_build
	reg_apply
}

function reg_build() {
	local tool_dir=$(kosaio_get_tool_dir "dcload-ip")
	log_info --draw-line "Building dcload-ip host tool..."
	# Ensure environment for cross-compiling the target if needed, 
	# but here we focus on the host tool dc-tool-ip
	(cd "${tool_dir}/host-src/tool" && make)
}

function reg_apply() {
	local tool_dir=$(kosaio_get_tool_dir "dcload-ip")
	mkdir -p "${DREAMCAST_BIN_PATH}"
	cp "${tool_dir}/host-src/tool/dc-tool-ip" "${DREAMCAST_BIN_PATH}/"
	log_success "dc-tool-ip installed."
}

function reg_export() {
	local tool_dir=$(kosaio_get_tool_dir "$ID")
	local host_out="${KOSAIO_DIR}/out/${ID}"
	
	log_info "Exporting ${NAME} to host..."
	
	if [ ! -f "${tool_dir}/host-src/tool/dc-tool-ip" ]; then
		log_error "dc-tool-ip not found. Run 'kosaio build ${ID}' first."
		return 1
	fi
	
	mkdir -p "${host_out}"
	cp -v "${tool_dir}/host-src/tool/dc-tool-ip" "${host_out}/"
	
	log_success "Export complete: ${host_out}/dc-tool-ip"
}

function reg_uninstall() {
	local tool_dir=$(kosaio_get_tool_dir "dcload-ip")
	rm -rf "$tool_dir"
	rm -f "${DREAMCAST_BIN_PATH}/dc-tool-ip"
}

function reg_update() {
	local tool_dir=$(kosaio_get_tool_dir "dcload-ip")
	kosaio_standard_update_flow "dcload-ip" "dcload-ip" "$tool_dir" "$@"
}
