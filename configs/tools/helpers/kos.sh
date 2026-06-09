#!/bin/bash
# configs/tools/helpers/kos.sh
# Tool hooks for KallistiOS: custom build (sources environ.sh), apply (generates environ.sh)
# Loaded automatically by helper_loader.sh

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
		log_error "SH4 Toolchain not found! Please run: kosaio build toolchain"
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
