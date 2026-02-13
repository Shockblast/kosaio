#!/bin/bash
# scripts/registry/core/toolchain.sh
# Manifest for Sega Dreamcast Toolchains (dc-chain)

ID="toolchain"
NAME="Dreamcast Toolchain"
DESC="The compiler suite (GCC/Binutils) for SH4 and ARM architectures."
TAGS="core,compiler,gcc,sh4,arm"
TYPE="core"
DEPS="bison build-essential bzip2 cmake curl diffutils flex gawk gettext git libelf-dev libgmp-dev libisofs-dev libjpeg-dev libmpc-dev libmpfr-dev libpng-dev make meson ninja-build patch pkg-config python3 rake sed tar texinfo wget"

source "${KOSAIO_DIR}/scripts/common/patch_utils.sh"

function reg_check_health() {
	local sh_gcc="${DREAMCAST_SDK}/sh-elf/bin/sh-elf-gcc"
	local arm_gcc="${DREAMCAST_SDK}/arm-eabi/bin/arm-eabi-gcc"
	
	if [ -f "$sh_gcc" ]; then
		return 0 # At least SH4 is ready, which is minimal requirement
	else
		return 1
	fi
}

function reg_info() {
	# Gather Status Data
	local sh_gcc="${DREAMCAST_SDK}/sh-elf/bin/sh-elf-gcc"
	local sh_ver="MISSING"
	local sh_status="${C_RED}NOT INSTALLED${C_RESET}"
	[ -f "$sh_gcc" ] && sh_ver=$($sh_gcc -dumpversion) && sh_status="${C_GREEN}READY (GCC $sh_ver)${C_RESET}"

	local sh_gdb="${DREAMCAST_SDK}/sh-elf/bin/sh-elf-gdb"
	local sh_gdb_status="${C_GRAY}Missing${C_RESET}"
	[ -f "$sh_gdb" ] && sh_gdb_status="${C_GREEN}INSTALLED${C_RESET}"

	local arm_gcc="${DREAMCAST_SDK}/arm-eabi/bin/arm-eabi-gcc"
	local arm_ver="MISSING"
	local arm_status="${C_RED}NOT INSTALLED${C_RESET}"
	[ -f "$arm_gcc" ] && arm_ver=$($arm_gcc -dumpversion) && arm_status="${C_GREEN}READY (GCC $arm_ver)${C_RESET}"
	
	# Render The Dashboard
	log_box --info "TOOLCHAIN STATUS REPORT" \
		"${C_YELLOW}SH4 (Game CPU):${C_RESET}   ${sh_status}" \
		"  Location:       ${sh_gcc}" \
		"  Debugger (GDB): ${sh_gdb_status}" \
		"" \
		"${C_YELLOW}ARM (Sound CPU):${C_RESET}  ${arm_status}" \
		"  Location:       ${arm_gcc}" \
		"" \
		"${C_YELLOW}Build Options:${C_RESET}" \
		"  ${C_CYAN}--all${C_RESET}          : Build SH4 + ARM + GDB" \
		"  ${C_CYAN}--only-sh${C_RESET}      : Build SH4 + GDB (Default)" \
		"  ${C_CYAN}--only-arm${C_RESET}     : Build only ARM" \
		"  ${C_CYAN}--with-gdb${C_RESET}     : Ensure SH4 GDB is built"
}

function reg_build() {
	local target=""
	local kos_dir=$(kosaio_get_tool_dir "kos")
	local dc_chain="${kos_dir}/utils/dc-chain"

	# If KOS source is missing, we can't build toolchain
	if [ ! -d "$kos_dir" ]; then
		log_error "KOS source missing at $kos_dir. Clone 'kos' first."
		return 1
	fi

	# Parse flags
	local build_arm=false
	local build_sh=false
	local build_gdb=false
	local force_all=false
	local no_patches=false

	for arg in "$@"; do
		case $arg in
			--all)      force_all=true ;;
			--only-arm) build_arm=true ;;
			--only-sh)  build_sh=true ;;
			--with-gdb) build_gdb=true ;;
			--no-patches) no_patches=true ;;
		esac
	done

	# Mapping logic to dc-chain targets
	if [ "$force_all" = true ]; then
		# Full Suite: SH4 + ARM + Debuggers (SH4-GDB)
		# Note: 'gdb' target builds SH4 GDB
		target="build-sh4 gdb build-arm"
	elif [ "$build_arm" = true ]; then
		target="build-arm"
	elif [ "$build_sh" = true ]; then
		target="build-sh4"
		[ "$build_gdb" = true ] && target="build-sh4 gdb"
	elif [ "$build_gdb" = true ]; then
		target="gdb"
	else
		# Default KOSAIO behavior: Main CPU + Debugger
		target="build-sh4 gdb"
	fi

	# 1. Critical Warning & Patching System
	if [[ "$target" == *"arm"* ]] || [ "$force_all" = true ]; then
		if [ "$no_patches" = true ]; then
			log_warn "User requested --no-patches. Skipping ARM toolchain fixes."
		else
			log_box --type=warn "TOOLCHAIN: AGGRESSIVE PATCHING" \
				"Building ARM toolchain requires dc-chain modification." \
				"${C_YELLOW}Context:${C_RESET} Enables Full ARM Newlib (for AICAOS)." \
				"${C_YELLOW}Action:${C_RESET} GCC Pass 2 compilation for ARM enabled." \
				"${C_YELLOW}Action:${C_RESET} Automated init.mk setup for AICA." \
				"These patches are applied automatically."
			
			# Apply patches to dc-chain
			kosaio_apply_patches "$dc_chain" "toolchain" || return 1
		fi
	fi

	log_info --draw-line "Building Toolchain Target: ${target:-standard (SH4+GDB)}..."
	
	# Sync settings
	mkdir -p "${dc_chain}"
	cp "${KOSAIO_DIR}/configs/dc-chain-settings.cfg" "${dc_chain}/Makefile.cfg"

	(cd "${dc_chain}" && make -j$(nproc) ${target})
}

function reg_install() {
	# Toolchain installation is just building it
	reg_build "$@"
}

function reg_uninstall() {
	log_warn "This will remove the entire Dreamcast Toolchain."
	log_warn "paths: ${DREAMCAST_SDK}/sh-elf, ${DREAMCAST_SDK}/arm-eabi"
	log_warn "Are you sure? (y/n)"
	read -r CONFIRM
	if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
		log_info "Removing Toolchain..."
		rm -rf "${DREAMCAST_SDK}/sh-elf"
		rm -rf "${DREAMCAST_SDK}/arm-eabi"
		
		log_success "Toolchain uninstalled."
	else
		log_info "Uninstallation cancelled."
	fi
}
