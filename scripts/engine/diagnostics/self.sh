#!/bin/bash
# scripts/registry/core/self.sh
# Self Diagnosis Manifest (KOSAIO Health)

ID="self"
NAME="KOSAIO Core Integrity"
DESC="Internal health check for KOSAIO engine and scripts"
TYPE="core"
TAGS="core,diag"

function reg_check_health() {
	local warnings=0
	local errors=0

	log_info "--- Repository Status ---"
	
	if [ -d "${KOSAIO_DIR}/.git" ]; then
		local current_hash=$(git -C "${KOSAIO_DIR}" rev-parse --short HEAD 2>/dev/null)
		local current_branch=$(git -C "${KOSAIO_DIR}" rev-parse --abbrev-ref HEAD 2>/dev/null)
		printf "  Version:     ${C_CYAN}%s${C_RESET} (%s)\n" "$current_hash" "$current_branch"
		
		if git -C "${KOSAIO_DIR}" diff-index --quiet HEAD --; then
			printf "  Git Status:  ${C_GREEN}Clean${C_RESET}\n"
		else
			printf "  Git Status:  ${C_YELLOW}Modified (Dirty)${C_RESET}\n"
			((warnings++)) || true
		fi
	else
		printf "  Git Status:  ${C_RED}NOT A GIT REPO${C_RESET}\n"
		((warnings++)) || true
	fi

	log_info "--- Engine Status ---"

	# Check Python Engine
	if python3 "${KOSAIO_DIR}/scripts/engine/py/main.py" --help >/dev/null 2>&1; then
		printf "  Python Engine: ${C_GREEN}OPERATIONAL${C_RESET}\n"
	else
		printf "  Python Engine: ${C_RED}FAILED${C_RESET}\n"
		((errors++)) || true
	fi

	# Check Critical Scripts
	local scripts=("scripts/kosaio" "scripts/controllers/router.sh" "scripts/engine/driver_manager.sh")
	for s in "${scripts[@]}"; do
		if [ -f "${KOSAIO_DIR}/${s}" ]; then
			printf "  %-25s: ${C_GREEN}OK${C_RESET}\n" "$s"
		else
			printf "  %-25s: ${C_RED}MISSING${C_RESET}\n" "$s"
			((errors++)) || true
		fi
	done

	if [ "$errors" -gt 0 ]; then
		return 2 # Broken
	elif [ "$warnings" -gt 0 ]; then
		return 0 # Healthy but with warnings (Standard exit code 0 implies functional)
	else
		return 0
	fi
}
