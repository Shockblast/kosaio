#!/bin/bash
set -Eeuo pipefail

# scripts/registry/tools/libdreamroq.sh
# Manifest for libdreamroq (RoQ Video Library)

ID="libdreamroq"
NAME="libdreamroq"
DESC="RoQ playback library for Dreamcast"
TAGS="video,roq,multimedia,library"
TYPE="lib"
DEPS="build-essential git"

function reg_check_health() {
	# 1. Require kos-ports
	[ -d "${KOS_PORTS_DIR}" ] || return 1
	
	# 2. Check source inside kos-ports
	local tool_dir="${KOS_PORTS_DIR}/${ID}"
	[ -d "$tool_dir" ] || return 2
	
	# 3. Check for the compiled library
	[ -f "${tool_dir}/libdreamroq.a" ] || return 3
	
	# 4. Check for headers link (created by Makefile)
	[ -d "${KOS_PORTS_DIR}/include/dreamroq" ] || return 4
	
	return 0
}

function reg_info() {
	local tool_dir="${KOS_PORTS_DIR}/${ID}"
	local status="${C_RED}Not Compiled${C_RESET}"
	local kos_ports_status="${C_GREEN}Found${C_RESET}"
	
	if [ ! -d "${KOS_PORTS_DIR}" ]; then
		kos_ports_status="${C_RED}MISSING${C_RESET}"
	fi

	if [ -f "${tool_dir}/libdreamroq.a" ]; then
		status="${C_GREEN}Compiled${C_RESET}"
	fi
	
	log_box --info "libdreamroq: RoQ Video Library" \
		"${C_YELLOW}Context:${C_RESET} High performance RoQ video decoding for Dreamcast." \
		"${C_YELLOW}Status:${C_RESET}  ${status}" \
		"${C_YELLOW}KOS-PORTS:${C_RESET} ${kos_ports_status}" \
		"${C_YELLOW}Path:${C_RESET}    ${tool_dir}" \
		"${C_YELLOW}Usage:${C_RESET}   Add ${C_CYAN}-ldreamroq${C_RESET} to your Makefile."
}

function reg_clone() {
	if [ ! -d "${KOS_PORTS_DIR}" ]; then
		log_error "KOS-PORTS is missing. libdreamroq requires it to be installed first."
		log_info "Tip: Run ${C_CYAN}kosaio install kos-ports${C_RESET}"
		return 1
	fi

	local tool_dir="${KOS_PORTS_DIR}/${ID}"
	log_info --draw-line "Cloning libdreamroq into KOS-PORTS..."
	kosaio_git_clone https://github.com/Shockblast/libdreamroq.git "${tool_dir}"
}

function reg_build() {
	local tool_dir="${KOS_PORTS_DIR}/${ID}"
	[ -d "$tool_dir" ] || { log_error "libdreamroq source missing. Run 'kosaio clone ${ID}' first."; return 1; }
	
	if [ -z "${KOS_BASE:-}" ]; then
		log_error "KOS_BASE is not set. KOS environment must be loaded to build libdreamroq."
		return 1
	fi

	log_info --draw-line "Building libdreamroq..."
	
	# We must ensure the parent include directory exists in kos-ports.
	mkdir -p "${KOS_PORTS_DIR}/include"

	# We use defaultall which builds lib, samples AND creates the symlink
	(cd "${tool_dir}" && make defaultall)
}

function reg_apply() {
	log_info "Verifying libdreamroq installation..."
	local tool_dir="${KOS_PORTS_DIR}/${ID}"
	local link_path="${KOS_PORTS_DIR}/include/dreamroq"

	# Check if it exists and is a valid directory (or valid link to directory)
	if [ -d "${link_path}" ]; then
		log_success "libdreamroq is ready in KOS-PORTS."
	else
		if [ -L "${link_path}" ]; then
			log_warn "Dangling symlink detected for dreamroq headers. Fixing..."
		else
			log_warn "Headers symlink missing. Attempting to fix..."
		fi
		
		if [ -d "${tool_dir}/include" ]; then
			mkdir -p "${KOS_PORTS_DIR}/include"
			ln -sf "../${ID}/include" "${link_path}"
			log_success "Headers link restored."
		else
			log_error "Cannot fix symlink: Source include directory missing at ${tool_dir}/include"
			return 1
		fi
	fi
}

function reg_install() {
	reg_clone
	reg_build
	reg_apply
	log_success "libdreamroq installation complete."
}

function reg_uninstall() {
	local tool_dir="${KOS_PORTS_DIR}/${ID}"
	rm -rf "$tool_dir"
	rm -f "${KOS_PORTS_DIR}/include/dreamroq"
	log_success "libdreamroq removed from KOS-PORTS."
}

function reg_update() {
	local tool_dir="${KOS_PORTS_DIR}/${ID}"
	kosaio_standard_update_flow "${ID}" "libdreamroq" "$tool_dir" "$@"
}

function reg_clean() {
	local tool_dir="${KOS_PORTS_DIR}/${ID}"
	[ -d "$tool_dir" ] && (cd "${tool_dir}" && make clean)
	log_success "libdreamroq cleaned."
}
