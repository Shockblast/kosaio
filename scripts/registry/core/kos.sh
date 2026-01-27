#!/bin/bash
set -Eeuo pipefail

# scripts/registry/core/kos.sh
# Manifest for KallistiOS (KOS)

ID="kos"
NAME="KallistiOS"
DESC="Main Dreamcast SDK Core"
TAGS="core,sdk,dreamcast"
TYPE="core"
DEPS="bison build-essential bzip2 cmake curl diffutils flex gawk gettext git libelf-dev libgmp-dev libisofs-dev libjpeg-dev libmpc-dev libmpfr-dev libpng-dev make meson ninja-build patch pkg-config python3 rake sed tar texinfo wget"

function reg_check_health() {
	[ -d "${KOS_DIR}" ] || return 1
	[ -f "${KOS_DIR}/environ.sh" ] || return 2
	[ -f "${KOS_DIR}/lib/dreamcast/libkallisti.a" ] || return 2
	return 0
}

function reg_clone() {
	log_info --draw-line "Cloning KOS repository..."
	kosaio_git_clone --recursive -b v2.2.x https://github.com/KallistiOS/KallistiOS.git "${KOS_DIR}"
}

function _build_toolchain() {
	local dc_chain="${KOS_DIR}/utils/dc-chain"
	mkdir -p "${dc_chain}"
	cp "${KOSAIO_DIR}/dc-chain-settings/Makefile.cfg" "${dc_chain}/"

	log_info --draw-line "Phase 1: Building dc-chain..."
	(cd "${dc_chain}" && make -j$(nproc))
}

function reg_build() {
	[ -d "${KOS_DIR}" ] || { log_error "KOS source missing. Run 'kosaio clone kos' first."; return 1; }

	local force_toolchain=false
	local only_kos=false

	# Parse args
	for arg in "$@"; do
		case $arg in
			--force-toolchain) force_toolchain=true ;;
			--only-kos) only_kos=true ;;
		esac
	done


	if [ "${force_toolchain}" = false ]; then
		log_info --draw-line "Building KOS..."
	else
		log_info --draw-line "Building KOS & Toolchain..."
	fi

	# Load environment to ensure KOS_DIR and others are set
	source "${KOSAIO_DIR}/scripts/common/env.sh"

	# 1. Toolchain Check
	local toolchain_ok=false
	if [ -x "/opt/toolchains/dc/sh-elf/bin/sh-elf-gcc" ]; then
		toolchain_ok=true
	fi

	if [ "$only_kos" = true ]; then
		log_info --draw-line "Skipping Toolchain (--only-kos)..."
	elif [ "$force_toolchain" = true ]; then
		log_info --draw-line "Forcing Toolchain rebuild..."
		_build_toolchain
	elif [ "$toolchain_ok" = true ]; then
		log_info --draw-line "Toolchain detected at /opt/toolchains/dc. Skipping build (Use --force-toolchain to rebuild)."
	else
		log_info --draw-line "Toolchain not found. Building..."
		_build_toolchain
	fi

	# 2. Build KOS core
	log_info --draw-line "Phase 2: Building KOS core..."
	# Force load the new environment headers directly to guarantee 'make' has them
	if [ -f "${KOS_DIR}/environ.sh" ]; then
		source "${KOS_DIR}/environ.sh"
	fi

	(cd "${KOS_DIR}" && make -j$(nproc))
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
	local stable_toolchain="/opt/toolchains/dc"
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
