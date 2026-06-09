#!/bin/bash
# configs/tools/helpers/flycast.sh
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
		"${C_YELLOW}Source:${C_RESET}  ${tool_dir}" \
		"${C_YELLOW}Flag:${C_RESET}   ${C_CYAN}--with-gdb${C_RESET} : Enable GDB Server for debugging" \
		"${C_YELLOW}Flag:${C_RESET}   ${C_CYAN}--debug${C_RESET}    : Debug build" \
		"${C_YELLOW}Flag:${C_RESET}   ${C_CYAN}--release${C_RESET}  : Release build (default)"
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

kosaio_translate_flycast_args() {
	KOSAIO_TRANSLATED_ARGS=()
	local build_system="${1:?}"
	shift

	local gdb_state="OFF"
	local build_type="Release"

	for arg in "$@"; do
		case "$arg" in
			--with-gdb)
				gdb_state="ON"
				;;
			--debug)
				build_type="Debug"
				;;
			--release)
				build_type="Release"
				;;
			*)
				KOSAIO_TRANSLATED_ARGS+=("$arg")
				;;
		esac
	done

	KOSAIO_TRANSLATED_ARGS=(
		"-DENABLE_GDB_SERVER=${gdb_state}"
		"-DCMAKE_BUILD_TYPE=${build_type}"
	)
}
