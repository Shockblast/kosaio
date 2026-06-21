#!/bin/bash
# scripts/registry/core/self.sh
# Self Diagnosis Manifest (KOSAIO Health)

ID="self"
NAME="KOSAIO Core Integrity"
DESC="Internal health check for KOSAIO engine and scripts"
TYPE="core"
TAGS="core,diag"

function kosaio_reg_check_health() {
	local warnings=0
	local errors=0

	log_info "--- Repository Status ---"

	if [ -d "${KOSAIO_DIR}/.git" ]; then
		local current_hash current_branch
		current_hash=$(git -C "${KOSAIO_DIR}" rev-parse --short HEAD 2>/dev/null)
		current_branch=$(git -C "${KOSAIO_DIR}" rev-parse --abbrev-ref HEAD 2>/dev/null)
		printf "  %-25s: ${C_CYAN}%s${C_RESET} (%s)\n" "Version" "$current_hash" "$current_branch"

		if git -C "${KOSAIO_DIR}" diff-index --quiet HEAD --; then
			printf "  %-25s: ${C_GREEN}Clean${C_RESET}\n" "Git Status"
		else
			printf "  %-25s: ${C_YELLOW}Modified (Dirty)${C_RESET}\n" "Git Status"
			warnings=$((warnings + 1))
		fi
	else
		printf "  %-25s: ${C_RED}NOT A GIT REPO${C_RESET}\n" "Git Status"
		warnings=$((warnings + 1))
	fi

	log_info "--- Engine Status ---"

	if python3 "${KOSAIO_DIR}/scripts/engine/py/main.py" --help >/dev/null 2>&1; then
		printf "  %-25s: ${C_GREEN}OPERATIONAL${C_RESET}\n" "Python Engine"
	else
		printf "  %-25s: ${C_RED}FAILED${C_RESET}\n" "Python Engine"
		errors=$((errors + 1))
	fi

	local py_pkg_ok=0
	for pkg in pytest; do
		if python3 -c "import $pkg" 2>/dev/null; then
			printf "  %-25s: ${C_GREEN}OK${C_RESET}\n" "Python $pkg"
		else
			printf "  %-25s: ${C_YELLOW}MISSING${C_RESET}\n" "Python $pkg"
			warnings=$((warnings + 1))
		fi
	done

	if [ -f "${KOSAIO_DIR}/scripts/engine/py/pyproject.toml" ]; then
		printf "  %-25s: ${C_GREEN}OK${C_RESET}\n" "pyproject.toml"
	else
		printf "  %-25s: ${C_YELLOW}MISSING${C_RESET}\n" "pyproject.toml"
		warnings=$((warnings + 1))
	fi

	log_info "--- Critical Scripts ---"

	local scripts=("scripts/kosaio" "scripts/controllers/router.sh" "scripts/engine/driver_manager.sh" "scripts/common/env.sh" "scripts/common/ui.sh" "scripts/common/completions.sh")
	for s in "${scripts[@]}"; do
		if [ -f "${KOSAIO_DIR}/${s}" ]; then
			printf "  %-35s: ${C_GREEN}OK${C_RESET}\n" "$s"
		else
			printf "  %-35s: ${C_RED}MISSING${C_RESET}\n" "$s"
			errors=$((errors + 1))
		fi
	done

	if command -v shellcheck >/dev/null 2>&1; then
		printf "  %-35s: ${C_GREEN}AVAILABLE${C_RESET}\n" "shellcheck"
	else
		printf "  %-35s: ${C_YELLOW}NOT INSTALLED${C_RESET}\n" "shellcheck"
		printf "  ${C_GRAY}  Tip: apt install shellcheck${C_RESET}\n"
		warnings=$((warnings + 1))
	fi

	log_info "--- Tests ---"

	if python3 -m pytest "${KOSAIO_DIR}/scripts/engine/py/tests/" -q --tb=no 2>/dev/null; then
		printf "  %-25s: ${C_GREEN}PASSING${C_RESET}\n" "Python Tests"
	else
		printf "  %-25s: ${C_YELLOW}FAILING${C_RESET}\n" "Python Tests"
		warnings=$((warnings + 1))
	fi

	if [ "$errors" -gt 0 ]; then
		return 2
	elif [ "$warnings" -gt 0 ]; then
		return 0
	else
		return 0
	fi
}
