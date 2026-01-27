#!/bin/bash
# scripts/registry/core/system.sh
# System Diagnosis Manifest

ID="system"
NAME="KOSAIO System Environment"
DESC="Host environment, toolchain, and critical variables"
TYPE="core"
TAGS="core,env,diag"

function reg_check_health() {
	local errors=0
	
	log_info "--- Environment Variables ---"
	
	local required_vars=("KOSAIO_DIR" "DREAMCAST_SDK" "PROJECTS_DIR")
	for var in "${required_vars[@]}"; do
		if [[ -v "$var" ]] && [ -n "${!var}" ] && [ -d "${!var}" ]; then
			printf "  %-20s: ${C_GREEN}CONNECTED${C_RESET} → %s\n" "$var" "${!var}"
		else
			printf "  %-20s: ${C_RED}DISCONNECTED${C_RESET}\n" "$var"
			((errors++)) || true
		fi
	done

	log_info "--- SH4 Toolchain (Main CPU) ---"
	local sh_gcc="/opt/toolchains/dc/sh-elf/bin/sh-elf-gcc"
	if [ -f "$sh_gcc" ]; then
		local v=$($sh_gcc -dumpversion 2>/dev/null || echo "Unknown")
		printf "  %-20s: ${C_GREEN}READY${C_RESET} (GCC %s)\n" "SH4 Compiler" "$v"
		printf "  %-20s: ${C_GRAY}%s${C_RESET}\n" "Location" "$sh_gcc"
	else
		printf "  %-20s: ${C_YELLOW}MISSING${C_RESET}\n" "SH4 Compiler"
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
		log_info "  ${C_GRAY}Tip: Build with 'kosaio build toolchain --only-arm'${C_RESET}"
	fi

	log_info "--- Host Tools ---"
	local host_tools=("make" "cmake" "git" "python3" "ninja" "meson")
	for tool in "${host_tools[@]}"; do
		if command -v "$tool" >/dev/null 2>&1; then
			printf "  %-20s: ${C_GREEN}OK${C_RESET}\n" "$tool"
		else
			printf "  %-20s: ${C_RED}MISSING${C_RESET}\n" "$tool"
			((errors++)) || true
		fi
	done

	if [ "$errors" -eq 0 ]; then
		return 0
	else
		return 2 # System Configuration / Tools Missing
	fi
}
