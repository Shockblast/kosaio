#!/bin/bash
# scripts/registry/hooks/toolchain.sh
# Tool hooks for Dreamcast Toolchain
# Supports both KOS v2 (utils/dc-chain/) and KOS v3 (utils/kos-chain/)
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
		"  ${C_CYAN}--with-gdb${C_RESET}     : Ensure SH4 GDB is built" \
		"  ${C_CYAN}--no-patches${C_RESET}   : Skip toolchain patches (v2 only)"
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

# --- Detect build system version ---
_kosaio_detect_version() {
	local kos_dir="$1"
	if [ -d "${kos_dir}/utils/kos-chain" ]; then
		echo "v3"
	elif [ -d "${kos_dir}/utils/dc-chain" ]; then
		echo "v2"
	else
		echo "unknown"
	fi
}

# --- v2 build (utils/dc-chain/) ---
_kosaio_build_v2() {
	local kos_dir="$1"; shift
	local dc_chain="${kos_dir}/utils/dc-chain"

	local build_arm=false
	local build_sh=false
	local build_gdb=false
	local force_all=false
	local no_patches=false

	for arg in "$@"; do
		case $arg in
			--all)      force_all=true  ;;
			--only-arm) build_arm=true  ;;
			--only-sh)  build_sh=true   ;;
			--with-gdb) build_gdb=true  ;;
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
			kosaio_apply_patches "$dc_chain" "kos-chain" || return 1
		fi
	fi

	log_info --draw-line "Building Toolchain Target (v2): ${target:-standard (SH4+GDB)}..."
	mkdir -p "${dc_chain}"
	cp "${KOSAIO_DIR}/configs/kos-v2-dreamcast.cfg" "${dc_chain}/Makefile.cfg"
	(cd "${dc_chain}" && make -j$(nproc) ${target})
}

# --- v3 build (utils/kos-chain/) ---
_kosaio_build_v3() {
	local kos_dir="$1"; shift
	local kos_chain="${kos_dir}/utils/kos-chain"

	local build_arm=false
	local build_sh=false
	local build_gdb=false
	local force_all=false

	for arg in "$@"; do
		case $arg in
			--all)      force_all=true  ;;
			--only-arm) build_arm=true  ;;
			--only-sh)  build_sh=true   ;;
			--with-gdb) build_gdb=true  ;;
		esac
	done

	# Determine what to build
	if [ "$force_all" = true ]; then
		build_sh=true
		build_arm=true
		build_gdb=true
	elif [ "$build_arm" = false ] && [ "$build_sh" = false ] && [ "$build_gdb" = false ]; then
		build_sh=true
		build_gdb=true
	fi

	# Copy config files
	cp "${KOSAIO_DIR}/configs/kos-v3-dreamcast.cfg" "${kos_chain}/Makefile.dreamcast.cfg"
	cp "${KOSAIO_DIR}/configs/kos-v3-aica.cfg" "${kos_chain}/Makefile.aica.cfg"

	# Build dreamcast (SH4) toolchain
	if [ "$build_sh" = true ]; then
		log_info --draw-line "Building SH4 toolchain (v3, platform=dreamcast)..."
		(cd "${kos_chain}" && make platform=dreamcast distclean 2>/dev/null; true)
		(cd "${kos_chain}" && make -j$(nproc) platform=dreamcast build) || return 1
	fi

	# Build GDB (needs SH4 toolchain)
	if [ "$build_gdb" = true ]; then
		log_info --draw-line "Building SH4 GDB (v3)..."
		(cd "${kos_chain}" && make platform=dreamcast gdb) || return 1
	fi

	# Build aica (ARM) toolchain
	if [ "$build_arm" = true ]; then
		log_info --draw-line "Building ARM toolchain (v3, platform=aica)..."
		(cd "${kos_chain}" && make platform=aica distclean 2>/dev/null; true)
		(cd "${kos_chain}" && make -j$(nproc) platform=aica build) || return 1
	fi
}

# --- Main build entry point ---
kosaio_tool_build() {
	local kos_dir=$(kosaio_get_tool_dir "kos")

	if [ ! -d "$kos_dir" ]; then
		log_error "KOS source missing at ${kos_dir}. Install 'kos' first."
		return 1
	fi

	local version=$(_kosaio_detect_version "$kos_dir")
	case "$version" in
		v3)
			log_info "Detected KOS v3 build system (utils/kos-chain/)"
			_kosaio_build_v3 "$kos_dir" "$@"
			;;
		v2)
			log_info "Detected KOS v2 build system (utils/dc-chain/)"
			_kosaio_build_v2 "$kos_dir" "$@"
			;;
		*)
			log_error "Cannot detect toolchain build system in ${kos_dir}/utils/"
			log_error "Expected utils/dc-chain/ (v2) or utils/kos-chain/ (v3)"
			return 1
			;;
	esac
}
