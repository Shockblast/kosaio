#!/bin/bash
# scripts/registry/hooks/mame.sh
# Tool hooks for MAME: custom build with RAM-aware throttling, Eggman mode, rich dashboard
# Loaded automatically by helper_loader.sh

kosaio_tool_info() {
	local tool_dir=$(__get_tool_dir)
	local binary="${tool_dir}/mame"
	local status="${C_RED}Not Compiled${C_RESET}"
	[ -f "$binary" ] && status="${C_GREEN}Compiled${C_RESET}"

	log_box --info "MAME: DREAMCAST OPTIMIZED" \
		"${C_YELLOW}Docs:${C_RESET} ${C_BLUE}https://docs.mamedev.org/initialsetup/compilingmame.html${C_RESET}" \
		"${C_YELLOW}Status:${C_RESET}  ${status}" \
		"${C_YELLOW}Source:${C_RESET}  ${tool_dir}" \
		"${C_YELLOW}Optimization:${C_RESET} Builds ${C_GREEN}dccons${C_RESET} driver only (Dreamcast)." \
		"${C_YELLOW}Mode:${C_RESET} Auto-scales build threads based on RAM to prevent crashes." \
		"${C_YELLOW}Config:${C_RESET} Edit with ${C_CYAN}kosaio config mame${C_RESET}" \
		"${C_YELLOW}Disk:${C_RESET}  Requires ~2GB storage (Dreamcast driver only)." \
		"${C_YELLOW}RAM:${C_RESET}   Requires 4GB+ RAM during linking phase." \
		"${C_YELLOW}BIOS:${C_RESET}  Requires MAME-compatible 'dc.zip' BIOS in rompath." \
		"${C_YELLOW}Export:${C_RESET} Binary exported as ${C_GREEN}mame${C_RESET}."
}

kosaio_tool_check_health() {
	local tool_dir=$(__get_tool_dir)
	local binary="${tool_dir}/mame"

	if [ ! -d "$tool_dir" ]; then
		log_box --info "MAME — Health Check" \
			"${C_YELLOW}Status:${C_RESET} ${C_RED}Not Installed${C_RESET}" \
			"" \
			"${C_RED}✗${C_RESET} Source missing at ${tool_dir}"
		return 1
	fi

	if [ ! -f "$binary" ]; then
		log_box --info "MAME — Health Check" \
			"${C_YELLOW}Status:${C_RESET} ${C_YELLOW}Source OK, Not Compiled${C_RESET}" \
			"" \
			"${C_GREEN}✓${C_RESET} Source: ${tool_dir}" \
			"${C_RED}✗${C_RESET} Binary: ${binary}"
		return 2
	fi

	log_box --info "MAME — Health Check" \
		"${C_YELLOW}Status:${C_RESET} ${C_GREEN}Healthy${C_RESET}" \
		"" \
		"${C_GREEN}✓${C_RESET} Source: ${tool_dir}" \
		"${C_GREEN}✓${C_RESET} Binary: ${binary}"
	return 0
}

kosaio_tool_build() {
	local tool_dir=$(__get_tool_dir)
	[ -d "$tool_dir" ] || { log_error "MAME source missing. Run 'kosaio clone mame' first."; return 1; }

	local use_full_power=0
	local use_debug=0

	for arg in "$@"; do
		[[ "$arg" == "--full-power" ]] && use_full_power=1
		[[ "$arg" == "--debug" ]] && use_debug=1
	done

	log_box --type=warn "HEAVY COMPILATION ALERT" \
		"${C_RED}Warning:${C_RESET} MAME build optimized for Dreamcast (~2GB Disk)." \
		"High RAM usage (4GB+) is still required during linking." \
		"Use ${C_YELLOW}--full-power${C_RESET} to ignore safeguards."

	local total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
	local total_ram_gb=$(( total_ram_kb / 1024 / 1024 ))
	local cpu_cores=$(nproc)
	local build_jobs=1

	if [ "$use_full_power" -eq 1 ]; then
		log_info "${C_YELLOW}EGGMAN MODE ACTIVATED: ALL SYSTEMS FULL POWER!${C_RESET}"
		build_jobs=$cpu_cores
	else
		local safe_jobs=$(( total_ram_gb * 10 / 25 ))
		[ "$safe_jobs" -lt 1 ] && safe_jobs=1
		[ "$safe_jobs" -gt "$cpu_cores" ] && build_jobs=$cpu_cores || build_jobs=$safe_jobs
		if [ "$safe_jobs" -lt "$cpu_cores" ]; then
			log_warn "Throttling build to $build_jobs threads (detected ${total_ram_gb}GB RAM)."
			log_info "Tip: Add --full-power to use all $cpu_cores cores."
		fi
	fi

	local symbols_val=0
	[ "$use_debug" -eq 1 ] && symbols_val=1

	if [ -z "${KOSAIO_NON_INTERACTIVE:-}" ] && [ "$use_full_power" -eq 0 ]; then
		confirm "Proceed with compilation using ${build_jobs} threads?" || return 1
	fi

	cd "${tool_dir}"
	log_info "Building MAME (Jobs: $build_jobs, Symbols: $symbols_val)..."
	make -j"$build_jobs" \
		SUBTARGET=mame \
		SOURCES=src/mame/sega/dccons.cpp \
		SYMBOLS="$symbols_val" \
		REGENIE=1 || return 1
}

kosaio_tool_install() {
	if [ -z "${KOSAIO_NON_INTERACTIVE:-}" ]; then
		log_box --type=warn "MASSIVE BUILD DETECTED" \
			"${C_YELLOW}Tip:${C_RESET} It is recommended to run ${C_CYAN}kosaio clone mame${C_RESET} first." \
			"Use ${C_CYAN}kosaio info mame${C_RESET} to view advanced compilation flags." \
			"Proceeding will use standard defaults (Dreamcast Optimized)."
		confirm "Continue with default installation?" || return 1
	fi

	log_info --draw-line "Cloning MAME repository..."
	kosaio_git_clone --branch mame0285 https://github.com/mamedev/mame.git "${KOSAIO_DIR}/tools/mame"

	kosaio_tool_build "$@"

	local binary="${KOSAIO_DIR}/tools/mame/mame"
	if [ -f "$binary" ]; then
		log_success "MAME installation complete."
		kosaio_tool_export
	else
		log_error "Build completed but binary not found at ${binary}."
		return 1
	fi
}

kosaio_tool_apply() {
	local tool_dir=$(__get_tool_dir)
	local binary="${tool_dir}/mame"

	if [ -f "$binary" ]; then
		log_info "MAME binary found. Exporting..."
		kosaio_tool_export
	else
		log_error "MAME binary not found at $binary. Build it first."
		return 1
	fi
}

kosaio_tool_export() {
	local tool_dir=$(__get_tool_dir)
	local host_out="${KOSAIO_DIR}/out/mame"
	local binary="${tool_dir}/mame"

	if [ ! -f "$binary" ]; then
		log_error "MAME binary not found at $binary. Run 'kosaio build mame' first."
		return 1
	fi

	mkdir -p "${host_out}"
	cp -v "$binary" "${host_out}/mame"
	log_success "Export complete: ${host_out}/mame"
}

kosaio_tool_uninstall() {
	local tool_dir=$(__get_tool_dir)
	rm -rf "$tool_dir"
	rm -rf "${KOSAIO_DIR}/out/mame"
	log_success "MAME removed."
}

kosaio_tool_update() {
	local tool_dir=$(__get_tool_dir)
	kosaio_standard_update_flow "mame" "MAME" "$tool_dir" "$@"
}

kosaio_tool_clean() {
	local tool_dir=$(__get_tool_dir)
	[ -d "$tool_dir" ] || return 0
	log_info --draw-line "Cleaning MAME build..."
	(cd "$tool_dir" && make clean)
	log_success "MAME build cleaned."
}
