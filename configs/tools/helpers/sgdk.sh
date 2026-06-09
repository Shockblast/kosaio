#!/bin/bash
# configs/tools/helpers/sgdk.sh
# Tool hook for SGDK: custom build (make -f makefile.gen + GDK export)
# Loaded automatically by helper_loader.sh

kosaio_tool_info() {
	local tool_dir=$(__get_tool_dir)
	local lib_status="${C_RED}Missing${C_RESET}"
	local cc_status="${C_RED}Not found${C_RESET}"

	[ -f "${tool_dir}/lib/libmd.a" ] && lib_status="${C_GREEN}Compiled${C_RESET}"
	command -v m68k-elf-gcc &>/dev/null && cc_status="${C_GREEN}Found${C_RESET}"

	log_box --info "SGDK: Sega Genesis Development Kit" \
		"${C_YELLOW}Context:${C_RESET} Sega Genesis/Mega Drive Development Kit." \
		"${C_YELLOW}Status:${C_RESET}  Library: ${lib_status}" \
		"${C_YELLOW}Compiler:${C_RESET} m68k-elf-gcc: ${cc_status}" \
		"${C_YELLOW}Warning:${C_RESET} Requires external m68k toolchain."
}

kosaio_tool_build() {
	local tool_dir=$(__get_tool_dir)

	if ! command -v m68k-elf-gcc &>/dev/null; then
		log_box --type=error "MISSING COMPILER" \
			"SGDK requires 'm68k-elf-gcc' locally installed." \
			"Please install it manually via package manager or MarsDev."
		return 1
	fi

	log_info --draw-line "Building SGDK Library..."

	export GDK="${tool_dir}"
	(cd "${tool_dir}" && make -f makefile.gen)
}
