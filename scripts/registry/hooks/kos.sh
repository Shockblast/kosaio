#!/bin/bash
# scripts/registry/hooks/kos.sh
# Tool hooks for KallistiOS: custom build (sources environ.sh), apply (generates environ.sh)
# Loaded automatically by helper_loader.sh

# ── Branch Resolution ──────────────────────────────────
# Reads the user's config (data/cfg/kos.cfg) or the default
# (scripts/registry/cfg/kos.cfg.default) to resolve the branch.
# Falls back to KOSAIO_TOOL_BRANCH from kos.tool.
_kosaio_kos_resolve_branch() {
	local cfg_path="${KOSAIO_DIR}/data/cfg/kos.cfg"
	local cfg_default="${KOSAIO_DIR}/scripts/registry/cfg/kos.cfg.default"
	local cfg_file=""

	[ -f "$cfg_path" ] && cfg_file="$cfg_path"
	[ -z "$cfg_file" ] && [ -f "$cfg_default" ] && cfg_file="$cfg_default"

	if [ -n "$cfg_file" ]; then
		source "$cfg_file"
	fi

	echo "${KOSAIO_TOOL_BRANCH:-master}"
}

kosaio_tool_clone() {
	local tool_dir=$(__get_tool_dir)

	local branch
	branch=$(_kosaio_kos_resolve_branch)

	log_info "Cloning KOS (branch: ${branch})..."
	kosaio_git_clone --branch "$branch" "${KOSAIO_TOOL_REPO}" "${tool_dir}"
}

kosaio_tool_update() {
	local tool_dir=$(__get_tool_dir)

	if [ ! -d "$tool_dir" ]; then
		log_error "KOS source not cloned yet. Run 'kosaio install kos' first."
		return 1
	fi

	local cfg_branch
	cfg_branch=$(_kosaio_kos_resolve_branch)

	cd "$tool_dir"

	local current_branch
	current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")

	if [ "$current_branch" != "$cfg_branch" ]; then
		log_info "Branch mismatch: current=${current_branch}, config=${cfg_branch}"
		if confirm "Switch KOS to branch '${cfg_branch}'? This may discard local changes." "N"; then
			if kosaio_git_checkout "$tool_dir" "$cfg_branch" true; then
				log_success "Switched KOS to branch '${cfg_branch}'."
				kosaio_reg_build
				kosaio_reg_apply
				return 0
			else
				log_error "Failed to switch KOS to branch '${cfg_branch}'."
				return 1
			fi
		else
			log_info "Keeping KOS on current branch '${current_branch}'."
		fi
	fi

	kosaio_standard_update_flow "kos" "KallistiOS" "$tool_dir" "$@"
}

kosaio_tool_info() {
	local tool_dir=$(__get_tool_dir)
	local lib_status="${C_RED}Not Compiled${C_RESET}"

	[ -f "${tool_dir}/lib/dreamcast/libkallisti.a" ] && lib_status="${C_GREEN}Compiled${C_RESET}"

	log_box --info "KALLISTIOS: SDK CORE" \
		"${C_YELLOW}Source:${C_RESET}  ${tool_dir}" \
		"${C_YELLOW}Status:${C_RESET}  ${lib_status}" \
		"${C_YELLOW}Build:${C_RESET}   Run ${C_CYAN}kosaio build kos${C_RESET} to compile libraries." \
		"${C_YELLOW}Note:${C_RESET}    Core SDK required for all Dreamcast development."
}

kosaio_tool_build() {
	local tool_dir=$(__get_tool_dir)

	if [ ! -f "${DREAMCAST_SDK}/sh-elf/bin/sh-elf-gcc" ]; then
		log_error "SH4 Toolchain not found! Please run: kosaio build kos-chain"
		return 3
	fi

	log_info --draw-line "Building KOS Libraries..."

	if [ -f "${tool_dir}/environ.sh" ]; then
		source "${tool_dir}/environ.sh"
	else
		log_warn "environ.sh not found. Auto-initializing KOS environment..."
		kosaio_tool_apply || return 1
		source "${tool_dir}/environ.sh"
	fi

	cd "${tool_dir}"
	make -j$(nproc)
}

kosaio_tool_apply() {
	local tool_dir=$(__get_tool_dir)

	[ -d "$tool_dir" ] || { log_error "KOS directory missing."; return 1; }

	log_info --draw-line "Configuring KOS Environment..."

	local target_env="${tool_dir}/environ.sh"
	local sample_env="${tool_dir}/doc/environ.sh.sample"

	if [ ! -f "${sample_env}" ]; then
		log_error "environ.sh.sample not found. Is KOS source correct?"
		return 1
	fi

	cp "${sample_env}" "${target_env}"

	sed -i "s|^#\? \?export KOS_BASE=.*|export KOS_BASE=\"${tool_dir}\"|g" "${target_env}"
	sed -i "s|^#\? \?export KOS_CC_BASE=.*|export KOS_CC_BASE=\"${DREAMCAST_SDK}/sh-elf\"|g" "${target_env}"
	sed -i "s|^#\? \?export DC_ARM_BASE=.*|export DC_ARM_BASE=\"${DREAMCAST_SDK}/arm-eabi\"|g" "${target_env}"
	sed -i "s|^#\? \?export DC_TOOLS_BASE=.*|export DC_TOOLS_BASE=\"${DREAMCAST_SDK}/bin\"|g" "${target_env}"
	sed -i "s|^#\? \?export KOS_SUBARCH=.*|export KOS_SUBARCH=\"pristine\"|g" "${target_env}"

	sed -i 's|^\. ${KOS_BASE}/environ_base.sh|export KOS_INC_PATHS_CPP=""\n. ${KOS_BASE}/environ_base.sh|' "${target_env}"

	log_success "KOS Environment configured at ${target_env}."
}

kosaio_tool_check_health() {
	local tool_dir=$(__get_tool_dir)

	if [ ! -d "$tool_dir" ]; then
		log_box --info "KallistiOS — Health Check" \
			"${C_YELLOW}Status:${C_RESET} ${C_RED}Not Installed${C_RESET}" \
			"" \
			"${C_RED}✗${C_RESET} Source missing at ${tool_dir}"
		return 1
	fi

	if [ ! -f "${DREAMCAST_SDK}/sh-elf/bin/sh-elf-gcc" ]; then
		log_box --info "KallistiOS — Health Check" \
			"${C_YELLOW}Status:${C_RESET} ${C_RED}Toolchain Missing${C_RESET}" \
			"" \
			"${C_GREEN}✓${C_RESET} Source: ${tool_dir}" \
			"${C_RED}✗${C_RESET} Toolchain: SH4 compiler not found"
		return 3
	fi

	if [ ! -f "${tool_dir}/lib/dreamcast/libkallisti.a" ]; then
		log_box --info "KallistiOS — Health Check" \
			"${C_YELLOW}Status:${C_RESET} ${C_YELLOW}Not Compiled${C_RESET}" \
			"" \
			"${C_GREEN}✓${C_RESET} Source: ${tool_dir}" \
			"${C_GREEN}✓${C_RESET} Toolchain: Ready" \
			"${C_RED}✗${C_RESET} Libraries: libkallisti.a not found"
		return 2
	fi

	log_box --info "KallistiOS — Health Check" \
		"${C_YELLOW}Status:${C_RESET} ${C_GREEN}Healthy${C_RESET}" \
		"" \
		"${C_GREEN}✓${C_RESET} Source: ${tool_dir}" \
		"${C_GREEN}✓${C_RESET} Toolchain: Ready" \
		"${C_GREEN}✓${C_RESET} Libraries: Compiled"
	return 0
}
