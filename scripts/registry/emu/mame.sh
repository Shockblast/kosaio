#!/bin/bash
set -Eeuo pipefail

# scripts/registry/emu/mame.sh
# Manifest for MAME (Dreamcast Driver)

ID="mame"
NAME="MAME (Dreamcast)"
DESC="Multi-purpose emulation framework (configured for Dreamcast)"
TAGS="emulator,testing,graphics"
TYPE="emulator"
DEPS="libsdl2-dev libsdl2-ttf-dev libfontconfig-dev qtbase5-dev build-essential python3 python3-pip git libpulse-dev libasound2-dev"

function reg_check_health() {
	local tool_dir=$(kosaio_get_tool_dir "mame")
	[ -d "$tool_dir" ] || return 1
	[ -f "${tool_dir}/mame" ] || return 2
	return 0
}

function reg_clone() {
	local tool_dir=$(kosaio_get_tool_dir "mame")
	log_info --draw-line "Cloning MAME repository..."
	# Cloning the specific tag/branch requested
	kosaio_git_clone --branch mame0285 https://github.com/mamedev/mame.git "${tool_dir}"
}

function reg_build() {
	local tool_dir=$(kosaio_get_tool_dir "mame")
	[ -d "$tool_dir" ] || { log_error "MAME source missing. Run 'kosaio clone mame' first."; return 1; }

	# 1. Visualize the impact
	log_box --type=warn "HEAVY COMPILATION ALERT" \
		"${C_RED}Warning:${C_RESET} MAME build optimized for Dreamcast (~2GB Disk)." \
		"High RAM usage (4GB+) is still required during linking." \
		"Use ${C_YELLOW}--full-power${C_RESET} to ignore safeguards."

	# 2. Parse local arguments for this specific tool
	local use_full_power=0
	local use_debug=0
	
	for arg in "$@"; do
		if [[ "$arg" == "--full-power" ]]; then
			use_full_power=1
		elif [[ "$arg" == "--debug" ]]; then
			use_debug=1
		fi
	done

	# 3. Intelligent Resource Calculation
	local total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
	local total_ram_gb=$(( total_ram_kb / 1024 / 1024 ))
	local cpu_cores=$(nproc)
	local build_jobs=1

	if [ "$use_full_power" -eq 1 ]; then
		log_info "🥚 ${C_YELLOW}EGGMAN MODE ACTIVATED: ALL SYSTEMS FULL POWER!${C_RESET}"
		build_jobs=$cpu_cores
	else
		# Heuristic: 1 Job per 2.5GB RAM aprox for MAME linking safety
		# 8GB RAM -> ~3 jobs. 16GB -> ~6 jobs.
		local safe_jobs=$(( total_ram_gb * 10 / 25 )) 
		[ "$safe_jobs" -lt 1 ] && safe_jobs=1
		
		# Cap at CPU cores
		if [ "$safe_jobs" -gt "$cpu_cores" ]; then
			build_jobs=$cpu_cores
		else
			build_jobs=$safe_jobs
			if [ "$safe_jobs" -lt "$cpu_cores" ]; then
				log_warn "Throttling build to $build_jobs threads (detected ${total_ram_gb}GB RAM)."
				log_info "Tip: Add --full-power to use all $cpu_cores cores."
			fi
		fi
	fi
	
	# Adjust for debug: symbols eat MUCH more RAM
	local symbols_val=0
	if [ "$use_debug" -eq 1 ]; then
		log_warn "Debug symbols enabled. This will increase RAM usage significantly during linking."
		symbols_val=1
	fi

	# 4. User Confirmation (skip if --yes was passed globally or full-power locally)
	if [ -z "${KOSAIO_NON_INTERACTIVE:-}" ] && [ "$use_full_power" -eq 0 ]; then
		confirm "Proceed with compilation using ${build_jobs} threads?" || return 1
	fi

	cd "${tool_dir}"

	log_info "Building optimized MAME (Driver: dccons, Jobs: $build_jobs, Symbols: $symbols_val)..."
	
	# COMMAND:
	# SYMBOLS=? : 0 for performance/size/RAM, 1 for debugging (eats RAM)
	# USE_SYSTEM_LIB_SDL2=0 : Bundled SDL (as per user request)
	make -j"$build_jobs" \
		SUBTARGET=mame \
		SOURCES=src/mame/sega/dccons.cpp \
		SYMBOLS="$symbols_val" \
		REGENIE=1 || return 1
}

function reg_apply() {
	local tool_dir=$(kosaio_get_tool_dir "mame")
	local binary="${tool_dir}/mame" # With SUBTARGET=mame, the binary is always 'mame'

	if [ ! -f "$binary" ]; then
		# Fallback check for Windows/weird builds or if SUBTARGET failed silently
		if [ -f "${tool_dir}/mame" ]; then
			binary="${tool_dir}/mame"
		else
			log_error "MAME binary not found ($binary). Build it first."
			return 1
		fi
	fi

	log_info "MAME binary found at $binary. Ready to export."
	reg_export
}

function reg_export() {
	local tool_dir=$(kosaio_get_tool_dir "$ID")
	local host_out="${KOSAIO_DIR}/out/${ID}"
	local binary="${tool_dir}/dreamcast"

	# Handle fallback if compilation didn't use subtarget successfully but produced 'mame'
	[ -f "$binary" ] || binary="${tool_dir}/mame"

	log_info "Exporting ${NAME} to host..."

	if [ ! -f "$binary" ]; then
		log_error "MAME binary not found. Run 'kosaio build ${ID}' first."
		return 1
	fi

	mkdir -p "${host_out}"
	cp -v "$binary" "${host_out}/mame" # Rename to 'mame' for consistency
	log_success "Export complete: ${host_out}/mame"
}

function reg_install() {
	if [ -z "${KOSAIO_NON_INTERACTIVE:-}" ]; then
		log_box --type=warn "MASSIVE BUILD DETECTED" \
			"${C_YELLOW}Tip:${C_RESET} It is recommended to run ${C_CYAN}kosaio clone mame${C_RESET} first." \
			"Use ${C_CYAN}kosaio info mame${C_RESET} to view advanced compilation flags." \
			"Proceeding will use standard defaults (Dreamcast Optimized)." \
			"${C_YELLOW}Note:${C_RESET} Use kosaio info mame to view important warnings."
		
		confirm "Continue with default installation?" || return 1
	fi

	reg_clone
	reg_build "$@"
	reg_apply
	log_success "MAME installation complete."
}

function reg_uninstall() {
	local tool_dir=$(kosaio_get_tool_dir "mame")
	rm -rf "$tool_dir"
	rm -rf "${KOSAIO_DIR}/out/mame"
	log_success "MAME removed."
}

function reg_update() {
	local tool_dir=$(kosaio_get_tool_dir "mame")
	kosaio_standard_update_flow "mame" "MAME" "$tool_dir" "$@"
}

function reg_clean() {
	local tool_dir=$(kosaio_get_tool_dir "mame")
	[ -d "${tool_dir}" ] || return 0
	log_info --draw-line "Cleaning MAME build..."
	(cd "${tool_dir}" && make clean)
	log_success "MAME build cleaned."
}

function reg_info() {
	log_box --info "MAME: DREAMCAST OPTIMIZED" \
		"${C_YELLOW}Docs:${C_RESET} ${C_BLUE}https://docs.mamedev.org/initialsetup/compilingmame.html${C_RESET}" \
		"${C_YELLOW}Optimization:${C_RESET} Default builds ${C_GREEN}'dreamcast'${C_RESET} driver only." \
		"${C_YELLOW}Mode:${C_RESET} Auto-scales build threads based on RAM to prevent crashes." \
		"${C_YELLOW}Flag:${C_RESET} Use ${C_CYAN}--full-power${C_RESET} to use ALL cores (Eggman Mode)." \
		"${C_YELLOW}Flag:${C_RESET} Use ${C_CYAN}--debug${C_RESET} to enable symbols (High RAM usage)." \
		"${C_YELLOW}Disk:${C_RESET} Requires ~2GB storage (Dreamcast driver only)." \
		"${C_YELLOW}RAM:${C_RESET}  Requires 4GB+ RAM during linking phase." \
		"${C_YELLOW}Exports:${C_RESET} Binary is exported as ${C_GREEN}mame${C_RESET} regardless of build mode." \
		"${C_YELLOW}BIOS:${C_RESET}    Requires MAME-compatible 'dc.zip' BIOS set in rompath." \
		"${C_RED}Runtime:${C_RESET} Requires ${C_MAGENTA}libSDL2${C_RESET} & ${C_MAGENTA}libSDL2_ttf${C_RESET} installed on Host."
}
