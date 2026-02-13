#!/bin/bash
set -Eeuo pipefail

# scripts/registry/core/kos.sh
# Manifest for KallistiOS (KOS)

ID="kos"
NAME="KallistiOS"
DESC="The main open-source SDK for the Sega Dreamcast (Libraries & SDK Core)."
TAGS="core,sdk,kallistios,os"
TYPE="core"
# Dependency: 'toolchain' (handled internally in reg_build)
DEPS=""

# --- Health Check ---
function reg_check_health() {
	local kos_dir=$(kosaio_get_tool_dir "kos")
	[ -d "$kos_dir" ] || return 1
	
	# Check if toolchain exists (minimal check)
	[ -f "${DREAMCAST_SDK}/sh-elf/bin/sh-elf-gcc" ] || return 3 # Toolchain missing
	
	# Check if KOS libraries are built
	[ -f "$kos_dir/lib/dreamcast/libkallisti.a" ] || return 2 # Not built
	
	return 0
}

# --- Metadata Extension (Used by kosaio info) ---
function reg_info() {
	local kos_dir=$(kosaio_get_tool_dir "kos")
	local lib_status="Missing"
	[ -f "$kos_dir/lib/dreamcast/libkallisti.a" ] && lib_status="${C_GREEN}Compiled${C_RESET}"

	log_box --info "KALLISTIOS: SDK CORE" \
		"${C_YELLOW}Source:${C_RESET}  ${kos_dir}" \
		"${C_YELLOW}Status:${C_RESET}  ${lib_status}" \
		"${C_YELLOW}Build:${C_RESET}   Run ${C_CYAN}kosaio build kos${C_RESET} to compile libraries." \
		"${C_YELLOW}Note:${C_RESET}    Core SDK required for all Dreamcast development."
}

# --- External Helpers ---

function reg_clone() {
	local kos_dir=$(kosaio_get_tool_dir "kos")
	log_info --draw-line "Cloning KOS repository..."
	kosaio_git_clone --recursive -b v2.2.x https://github.com/KallistiOS/KallistiOS.git "${kos_dir}"
}

function reg_build() {
	local kos_dir=$(kosaio_get_tool_dir "kos")
	[ -d "$kos_dir" ] || { log_error "KOS source missing."; return 1; }

	# Ensure toolchain is at least present
	if [ ! -f "${DREAMCAST_SDK}/sh-elf/bin/sh-elf-gcc" ]; then
		log_error "SH4 Toolchain not found! Please run: kosaio build toolchain"
		return 3
	fi

	log_info --draw-line "Building KOS Libraries..."
	
	# Load environment
	if [ -f "${kos_dir}/environ.sh" ]; then
		source "${kos_dir}/environ.sh"
	else
		log_warn "environ.sh not found. Auto-initializing KOS environment..."
		reg_apply || return 1
		# Now that we've applied, try sourcing again
		if [ -f "${kos_dir}/environ.sh" ]; then
			source "${kos_dir}/environ.sh"
		else
			log_error "Failed to initialize environment. Please run 'kossaio apply kos' manually."
			return 1
		fi
	fi

	(cd "${kos_dir}" && make -j$(nproc))
}


function reg_apply() {
	[ -d "${KOS_DIR}" ] || { log_error "KOS directory missing."; return 1; }

	log_info --draw-line "Configuring KOS Environment..."
	local target_env="${KOS_DIR}/environ.sh"
	local sample_env="${KOS_DIR}/doc/environ.sh.sample"

	if [ ! -f "${sample_env}" ]; then
		log_error "environ.sh.sample not found. Is KOS source correct?"
		return 1
	fi

	cp "${sample_env}" "${target_env}"

	sed -i "s|^#\? \?export KOS_BASE=.*|export KOS_BASE=\"${KOS_DIR}\"|g" "${target_env}"
	local stable_toolchain="${DREAMCAST_SDK}"
	sed -i "s|^#\? \?export KOS_CC_BASE=.*|export KOS_CC_BASE=\"${stable_toolchain}/sh-elf\"|g" "${target_env}"
	sed -i "s|^#\? \?export DC_ARM_BASE=.*|export DC_ARM_BASE=\"${stable_toolchain}/arm-eabi\"|g" "${target_env}"
	sed -i "s|^#\? \?export DC_TOOLS_BASE=.*|export DC_TOOLS_BASE=\"${stable_toolchain}/bin\"|g" "${target_env}"
	sed -i "s|^#\? \?export KOS_SUBARCH=.*|export KOS_SUBARCH=\"pristine\"|g" "${target_env}"
	
	# Fix for unbound variable error in environ_base.sh when using set -u
	# Must be inserted BEFORE environ_base.sh is sourced
	sed -i 's|^\. ${KOS_BASE}/environ_base.sh|export KOS_INC_PATHS_CPP=""\n. ${KOS_BASE}/environ_base.sh|' "${target_env}"

	log_success "KOS Environment configured at ${target_env}."
}

function reg_install() {
	reg_clone
	reg_apply
	reg_build "$@"
	
	log_info --draw-line "Phase 3: Environment Reload Required"
	log_success "KOS Installation complete."
	log_warn "You must reload your shell to apply the new KOS environment variables."
	log_info "  > Run the alias: ${C_B_CYAN}reload${C_RESET}"
}

function reg_uninstall() {
	rm -rf "${KOS_DIR}"
	log_success "KOS removed."
}

function reg_update() {
	kosaio_standard_update_flow "kos" "KOS core" "${KOS_DIR}" "$@"
}

function reg_clean() {
	[ -d "${KOS_DIR}" ] || return 0
	log_info --draw-line "Cleaning KOS source tree..."
	(cd "${KOS_DIR}" && make clean)
	log_success "KOS source tree cleaned."
}
