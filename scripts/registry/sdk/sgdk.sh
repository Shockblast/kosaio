#!/bin/bash
set -Eeuo pipefail

# scripts/registry/sdk/sgdk.sh
# Manifest for SGDK (Sega Genesis Development Kit)

ID="sgdk"
NAME="SGDK"
DESC="Sega Genesis Development Kit (C Library & Tools)"
TAGS="sdk,genesis,megadrive,m68k"
TYPE="sdk"
# Requires Java for rescomp/tools
DEPS="openjdk-17-jre git build-essential"

function reg_check_health() {
	local tool_dir=$(kosaio_get_tool_dir "sgdk")
	[ -d "$tool_dir" ] || return 1
	# Check for main library
	[ -f "${tool_dir}/lib/libmd.a" ] || return 2
	return 0
}

function reg_info() {
	local tool_dir=$(kosaio_get_tool_dir "sgdk")
	local lib_status="${C_RED}Missing${C_RESET}"
	[ -f "${tool_dir}/lib/libmd.a" ] && lib_status="${C_GREEN}Compiled${C_RESET}"
	
	local cc_status="${C_RED}Missing${C_RESET}"
	if command -v m68k-elf-gcc &> /dev/null; then
		cc_status="${C_GREEN}Found ($(m68k-elf-gcc -dumpversion))${C_RESET}"
	else
		cc_status="${C_YELLOW}Not found (Required)${C_RESET}"
	fi

	log_box --info "SGDK: Sega Genesis Development Kit" \
		"${C_YELLOW}Context:${C_RESET} Sega Genesis/Mega Drive Development Kit." \
		"${C_YELLOW}Status:${C_RESET}  Library: ${lib_status}" \
		"${C_YELLOW}Compiler:${C_RESET} m68k-elf-gcc: ${cc_status}" \
		"${C_YELLOW}Warning:${C_RESET} Requires external m68k toolchain (not yet auto-managed)."
}

function reg_clone() {
	local tool_dir=$(kosaio_get_tool_dir "sgdk")
	log_info --draw-line "Cloning SGDK..."
	kosaio_git_clone --recursive https://github.com/Stephane-D/SGDK.git "${tool_dir}"
}

function reg_build() {
	local tool_dir=$(kosaio_get_tool_dir "sgdk")
	[ -d "$tool_dir" ] || { log_error "SGDK source missing."; return 1; }

	if ! command -v m68k-elf-gcc &> /dev/null; then
		log_box --type=error "MISSING COMPILER" \
			"SGDK requires 'm68k-elf-gcc' locally installed." \
			"KOSAIO does not yet provide a Genesis toolchain." \
			"Please install it manually via package manager or MarsDev."
		return 1
	fi

	log_info --draw-line "Building SGDK Library..."
	
	# SGDK usually needs GDK winir env var, but on Linux makefile handles it relative
	export GDK="${tool_dir}"
	(cd "${tool_dir}" && make -f makefile.gen)
}

function reg_install() {
	reg_clone
	reg_build
	log_success "SGDK installed (Experimental)."
}

function reg_uninstall() {
	local tool_dir=$(kosaio_get_tool_dir "sgdk")
	rm -rf "$tool_dir"
	log_success "SGDK removed."
}

function reg_update() {
	local tool_dir=$(kosaio_get_tool_dir "sgdk")
	kosaio_standard_update_flow "sgdk" "SGDK" "$tool_dir" "$@"
}
