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
	local errors=0
	
	log_info "--- SH4 Toolchain (Main CPU) ---"
	local sh_gcc="/opt/toolchains/dc/sh-elf/bin/sh-elf-gcc"
	if [ -f "$sh_gcc" ]; then
		local v=$($sh_gcc -dumpversion 2>/dev/null || echo "Unknown")
		printf "  %-20s: ${C_GREEN}READY${C_RESET} (GCC %s)\n" "SH4 Compiler" "$v"
		printf "  %-20s: ${C_GRAY}%s${C_RESET}\n" "Location" "$sh_gcc"
	else
		printf "  %-20s: ${C_RED}MISSING${C_RESET}\n" "SH4 Compiler"
		((errors++)) || true
	fi

	local sh_gdb="/opt/toolchains/dc/sh-elf/bin/sh-elf-gdb"
	if [ -f "$sh_gdb" ]; then
		printf "  %-20s: ${C_GREEN}READY${C_RESET}\n" "GDB Debugger"
	else
		printf "  %-20s: ${C_GRAY}NOT INSTALLED${C_RESET}\n" "GDB Debugger"
	fi

	log_info "--- ARM Toolchain (AICA SPU) ---"
	local arm_gcc="/opt/toolchains/dc/arm-eabi/bin/arm-eabi-gcc"
	if [ -f "$arm_gcc" ]; then
		local v=$($arm_gcc -dumpversion 2>/dev/null || echo "Unknown")
		printf "  %-20s: ${C_GREEN}READY${C_RESET} (GCC %s)\n" "ARM Compiler" "$v"
		printf "  %-20s: ${C_GRAY}%s${C_RESET}\n" "Location" "$arm_gcc"
	else
		printf "  %-20s: ${C_YELLOW}DEACTIVATED${C_RESET}\n" "ARM Compiler"
		log_info "  ${C_GRAY}Tip: Run 'kosaio build toolchain --only-arm' to enable sound support.${C_RESET}"
	fi

	if [ "$errors" -eq 0 ]; then
		return 0
	else
		return 2 # Incomplete toolchain
	fi
}

function reg_info() {
	# Delegate to health check for the visual report
	reg_check_health
	
	echo ""
	echo -e "${C_B_CYAN}BUILD OPTIONS:${C_RESET}"
	echo -e "  ${C_CYAN}--all${C_RESET}          Build SH4 + ARM + GDB"
	echo -e "  ${C_CYAN}--only-sh${C_RESET}      Build SH4 + GDB (Default)"
	echo -e "  ${C_CYAN}--only-arm${C_RESET}     Build only ARM toolchain"
	echo -e "  ${C_CYAN}--with-gdb${C_RESET}     Ensure GDB is built (with --only-sh)"
	echo -e "  ${C_CYAN}--no-patches${C_RESET}   Skip automatic ARM toolchain patching"
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
		target="all"
	elif [ "$build_arm" = true ]; then
		target="build-arm"
	elif [ "$build_sh" = true ]; then
		[ "$build_gdb" = true ] && target="" || target="build-sh4"
	elif [ "$build_gdb" = true ]; then
		target="gdb"
	else
		# Default: Standard (SH4 + GDB)
		target=""
	fi

	# 1. Critical Warning & Patching System
	if [[ "$target" == *"arm"* ]] || [ "$force_all" = true ]; then
		if [ "$no_patches" = true ]; then
			log_warn "User requested --no-patches. Skipping ARM toolchain fixes."
		else
			log_alert_box "TOOLCHAIN: AGGRESSIVE PATCHING ACTIVE" \
				"Building the ARM toolchain requires modifying dc-chain scripts." \
				"KOSAIO will now apply custom patches to enable:" \
				"1. Full ARM Newlib support (Required for AICAOS)." \
				"2. GCC Pass 2 compilation for ARM." \
				"3. Automated init.mk variables for AICA." \
				"" \
				"These changes are necessary for modern AICA development."
			
			# Apply patches to dc-chain
			kosaio_apply_patches "$dc_chain" "toolchain" || return 1
		fi
	fi

	log_info --draw-line "Building Toolchain Target: ${target:-standard (SH4+GDB)}..."
	
	# Sync settings
	mkdir -p "${dc_chain}"
	cp "${KOSAIO_DIR}/dc-chain-settings/Makefile.cfg" "${dc_chain}/"

	(cd "${dc_chain}" && make -j$(nproc) ${target})
}

function reg_install() {
	# Toolchain installation is just building it
	reg_build "$@"
}
