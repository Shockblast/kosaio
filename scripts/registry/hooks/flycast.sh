#!/bin/bash
# scripts/registry/hooks/flycast.sh
# Prebuild arg translator for Flycast: --with-gdb, --debug, --release
# Loaded automatically by helper_loader.sh

KOSAIO_TRANSLATED_ARGS=()

kosaio_tool_info() {
	local tool_dir=$(__get_tool_dir)
	local binary="${tool_dir}/build/flycast"
	local status="${C_RED}Not Compiled${C_RESET}"
	[ -f "$binary" ] && status="${C_GREEN}Compiled${C_RESET}"

	log_box --info "FLYCAST: DREAMCAST EMULATOR" \
		"${C_YELLOW}Status:${C_RESET}  ${status}" \
		"${C_YELLOW}Source:${C_RESET}  ${tool_dir}"
}

kosaio_tool_check_health() {
	local tool_dir=$(__get_tool_dir)
	local binary="${tool_dir}/build/flycast"

	if [ ! -d "$tool_dir" ]; then
		log_box --info "Flycast — Health Check" \
			"${C_YELLOW}Status:${C_RESET} ${C_RED}Not Installed${C_RESET}" \
			"" \
			"${C_RED}✗${C_RESET} Source missing at ${tool_dir}"
		return 1
	fi

	if [ ! -f "$binary" ]; then
		log_box --info "Flycast — Health Check" \
			"${C_YELLOW}Status:${C_RESET} ${C_YELLOW}Not Compiled${C_RESET}" \
			"" \
			"${C_GREEN}✓${C_RESET} Source: ${tool_dir}" \
			"${C_RED}✗${C_RESET} Binary: ${binary}"
		return 2
	fi

	log_box --info "Flycast — Health Check" \
		"${C_YELLOW}Status:${C_RESET} ${C_GREEN}Healthy${C_RESET}" \
		"" \
		"${C_GREEN}✓${C_RESET} Source: ${tool_dir}" \
		"${C_GREEN}✓${C_RESET} Binary: ${binary}"
	return 0
}
