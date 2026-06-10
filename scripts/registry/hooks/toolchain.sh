#!/bin/bash
# scripts/registry/hooks/toolchain.sh
# Tool hooks for Dreamcast Toolchain (dc-chain in KOS utils)
# Builds SH4 + ARM toolchains via kos/utils/dc-chain
# Loaded automatically by helper_loader.sh

kosaio_tool_info() {
	local sh_gcc="${DREAMCAST_SDK}/sh-elf/bin/sh-elf-gcc"
	local arm_gcc="${DREAMCAST_SDK}/arm-eabi/bin/arm-eabi-gcc"
	local sh_gdb="${DREAMCAST_SDK}/sh-elf/bin/sh-elf-gdb"

	local sh_status="${C_RED}NOT INSTALLED${C_RESET}"
	local sh_ver=""
	local arm_status="${C_RED}NOT INSTALLED${C_RESET}"
	local arm_ver=""
	local gdb_status="${C_GRAY}Missing${C_RESET}"

	if [ -f "$sh_gcc" ]; then
		sh_ver=$("$sh_gcc" --version | head -1 | sed 's/.*\([0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/')
		sh_status="${C_GREEN}READY (GCC ${sh_ver})${C_RESET}"
	fi

	if [ -f "$arm_gcc" ]; then
		arm_ver=$("$arm_gcc" --version | head -1 | sed 's/.*\([0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/')
		arm_status="${C_GREEN}READY (GCC ${arm_ver})${C_RESET}"
	fi

	if [ -f "$sh_gdb" ]; then
		gdb_status="${C_GREEN}INSTALLED${C_RESET}"
	fi

	log_box --info "TOOLCHAIN STATUS REPORT" \
		"${C_YELLOW}SH4 (Game CPU):${C_RESET}   ${sh_status}" \
		"  ${C_YELLOW}Debugger (GDB):${C_RESET} ${gdb_status}" \
		"" \
		"${C_YELLOW}ARM (Sound CPU):${C_RESET}  ${arm_status}" \
		"" \
		"${C_YELLOW}Build Options:${C_RESET}" \
		"  ${C_CYAN}--all${C_RESET}          : Build SH4 + ARM + GDB" \
		"  ${C_CYAN}--only-sh${C_RESET}      : Build SH4 + GDB (Default)" \
		"  ${C_CYAN}--only-arm${C_RESET}     : Build only ARM" \
		"  ${C_CYAN}--with-gdb${C_RESET}     : Ensure SH4 GDB is built"
}

kosaio_tool_check_health() {
	local sh_gcc="${DREAMCAST_SDK}/sh-elf/bin/sh-elf-gcc"
	local arm_gcc="${DREAMCAST_SDK}/arm-eabi/bin/arm-eabi-gcc"
	local sh_gdb="${DREAMCAST_SDK}/sh-elf/bin/sh-elf-gdb"

	local sh_ok=0; [ -f "$sh_gcc" ] && sh_ok=1
	local arm_ok=0; [ -f "$arm_gcc" ] && arm_ok=1
	local gdb_ok=0; [ -f "$sh_gdb" ] && gdb_ok=1

	local sh_icon="${C_RED}✗${C_RESET}"; [ "$sh_ok" -eq 1 ] && sh_icon="${C_GREEN}✓${C_RESET}"
	local arm_icon="${C_RED}✗${C_RESET}"; [ "$arm_ok" -eq 1 ] && arm_icon="${C_GREEN}✓${C_RESET}"
	local gdb_icon="${C_RED}✗${C_RESET}"; [ "$gdb_ok" -eq 1 ] && gdb_icon="${C_GREEN}✓${C_RESET}"

	if [ "$sh_ok" -eq 0 ]; then
		log_box --info "Dreamcast Toolchain — Health Check" \
			"${C_YELLOW}Status:${C_RESET} ${C_RED}Not Installed${C_RESET}" \
			"" \
			"${sh_icon} SH4 (Game CPU):    $sh_gcc" \
			"${arm_icon} ARM (Sound CPU):   $arm_gcc" \
			"${gdb_icon} Debugger (GDB):    $sh_gdb"
		return 1
	fi

	if [ "$arm_ok" -eq 0 ] || [ "$gdb_ok" -eq 0 ]; then
		log_box --type=warn "Dreamcast Toolchain — Health Check" \
			"${C_YELLOW}Status:${C_RESET} ${C_YELLOW}Partial${C_RESET} (SH4 present, some components missing)" \
			"" \
			"${sh_icon} SH4 (Game CPU):    $sh_gcc" \
			"${arm_icon} ARM (Sound CPU):   $arm_gcc" \
			"${gdb_icon} Debugger (GDB):    $sh_gdb"
		return 2
	fi

	log_box --info "Dreamcast Toolchain — Health Check" \
		"${C_YELLOW}Status:${C_RESET} ${C_GREEN}Healthy${C_RESET}" \
		"" \
		"${sh_icon} SH4 (Game CPU):    $sh_gcc" \
		"${arm_icon} ARM (Sound CPU):   $arm_gcc" \
		"${gdb_icon} Debugger (GDB):    $sh_gdb"
	return 0
}

kosaio_tool_install() {
	kosaio_tool_build "$@"
}

kosaio_tool_build() {
	local kos_dir=$(kosaio_get_tool_dir "kos")
	local dc_chain="${kos_dir}/utils/dc-chain"

	if [ ! -d "$kos_dir" ]; then
		log_error "KOS source missing at ${kos_dir}. Install 'kos' first."
		return 1
	fi

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

	local target=""
	if [ "$force_all" = true ]; then
		target="build-sh4 gdb build-arm"
	elif [ "$build_arm" = true ]; then
		target="build-arm"
	elif [ "$build_sh" = true ]; then
		target="build-sh4"
		[ "$build_gdb" = true ] && target="build-sh4 gdb"
	elif [ "$build_gdb" = true ]; then
		target="gdb"
	else
		target="build-sh4 gdb"
	fi

	if [[ "$target" == *"arm"* ]] || [ "$force_all" = true ]; then
		if [ "$no_patches" = true ]; then
			log_warn "User requested --no-patches. Skipping ARM toolchain fixes."
		else
			log_box --type=warn "TOOLCHAIN: AGGRESSIVE PATCHING" \
				"Building ARM toolchain requires dc-chain modification." \
				"These patches are applied automatically."

			kosaio_apply_patches "$dc_chain" "toolchain" || return 1
		fi
	fi

	log_info --draw-line "Building Toolchain Target: ${target:-standard (SH4+GDB)}..."

	mkdir -p "${dc_chain}"
	cp "${KOSAIO_DIR}/configs/dc-chain-settings.cfg" "${dc_chain}/Makefile.cfg"

	(cd "${dc_chain}" && make -j$(nproc) ${target})
}

kosaio_tool_uninstall() {
	if confirm "This will remove the entire Dreamcast Toolchain (${DREAMCAST_SDK}/sh-elf, ${DREAMCAST_SDK}/arm-eabi). Are you sure?" "N"; then
		log_info "Removing Toolchain..."
		rm -rf "${DREAMCAST_SDK}/sh-elf"
		rm -rf "${DREAMCAST_SDK}/arm-eabi"
		log_success "Toolchain uninstalled."
	else
		log_info "Uninstallation cancelled."
	fi
}
