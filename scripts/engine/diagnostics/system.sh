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
			printf "  %-20s: ${C_GREEN}OK${C_RESET} (${!var})\n" "$var"
		else
			printf "  %-20s: ${C_RED}MISSING/INVALID${C_RESET}\n" "$var"
			((errors++)) || true
		fi
	done

	log_info "--- Toolchain Status ---"
	
	local tools=("sh-elf-gcc" "arm-eabi-gcc" "make" "cmake" "git" "python3")
	for tool in "${tools[@]}"; do
		if command -v "$tool" >/dev/null 2>&1; then
			local version=$($tool --version 2>&1 | head -n 1 | awk '{print $NF}' | cut -c 1-10) 
			# Clean up version string if too messy
			if [[ "$version" == *","* ]]; then version="Detected"; fi
			printf "  %-20s: ${C_GREEN}OK${C_RESET}\n" "$tool"
		else
			printf "  %-20s: ${C_RED}NOT FOUND${C_RESET}\n" "$tool"
			((errors++)) || true
		fi
	done

	if [ "$errors" -eq 0 ]; then
		return 0
	else
		return 2 # System Configuration / Tools Missing
	fi
}
