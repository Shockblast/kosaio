#!/bin/bash
# KOSAIO Shell Initialization
# This script is sourced when entering the container via kosaio-shell

# 1. Source standard bashrc (With Recursive Guard)
# If we are already running via shell-init source, skip to avoid infinite loop.
if [ -z "${KOSAIO_SHELL_GUARD:-}" ]; then
	export KOSAIO_SHELL_GUARD=1
	
	function _kosaio_guard_init() {
		# Only source system bashrc if we aren't already inside it
		# Check the call stack to see if .bashrc is an ancestor
		local sourcing_bashrc=0
		for source_file in "${BASH_SOURCE[@]}"; do
			if [[ "$source_file" == *".bashrc" ]]; then
				sourcing_bashrc=1
				break
			fi
		done

		if [ "$sourcing_bashrc" -eq 0 ] && [ -f /root/.bashrc ]; then
			source /root/.bashrc
		fi
	}
	_kosaio_guard_init
	unset -f _kosaio_guard_init
fi

# 2. Setup KOSAIO Environment
export KOSAIO_DIR="/opt/kosaio"
export PATH="${KOSAIO_DIR}/scripts:$PATH"

# 3. Load Environment & UI
[ -f "${KOSAIO_DIR}/scripts/common/env.sh" ] && source "${KOSAIO_DIR}/scripts/common/env.sh"
[ -f "${KOSAIO_DIR}/scripts/common/ui.sh" ] && source "${KOSAIO_DIR}/scripts/common/ui.sh"
[ -f "${KOSAIO_DIR}/scripts/common/kos_pivot.sh" ] && source "${KOSAIO_DIR}/scripts/common/kos_pivot.sh"
[ -f "${KOSAIO_DIR}/scripts/common/completions.sh" ] && source "${KOSAIO_DIR}/scripts/common/completions.sh"
[ -f "${KOSAIO_DIR}/scripts/common/update_check.sh" ] && source "${KOSAIO_DIR}/scripts/common/update_check.sh"

# Ensure aliases are expanded
shopt -s expand_aliases
kosaio_kos_pivot >/dev/null 2>&1

# --- Environment Management ---
function kreload() {
	# 1. Pivot KOS (updates KOS_BASE, PATH, etc.)
	if [ "$(type -t kosaio_kos_pivot)" == "function" ]; then
		kosaio_kos_pivot >/dev/null 2>&1
	fi
	# 2. Reload shell-init (refreshes prompt, aliases, etc.)
	unset KOSAIO_BANNER_SHOWN
	source "${KOSAIO_DIR}/scripts/shell-init.sh"
}

alias ksdk='cd /opt/toolchains/dc'
alias kkos='cd ${KOS_BASE}'
alias kports='cd ${KOS_PORTS_DIR}'
alias kproj='cd /opt/projects'
alias kreload='kreload'

# --- Dynamic Prompt (PS1) ---
# Contextual prompt: [CONTEXT(:BRANCH) : MODE] /path/to/dir #
function _kosaio_set_prompt() {
	local EXIT="$?"
	# PS1 requires \[ \] wrappers for non-printing characters
	local P_RESET="\[\033[0m\]"
	local P_GRAY="\[\033[38;5;242m\]"
	local P_WHITE="\[\033[38;5;253m\]"
	local P_PATH="\[\033[38;5;33m\]"
	
	# Sega Colors (256-bit)
	local SEGA_ORANGE="\[\033[38;5;208m\]"
	local SEGA_BLUE="\[\033[38;5;33m\]"
	local SEGA_RED="\[\033[38;5;196m\]"

	# 1. Determine Context & Path
	local CONTEXT="KOS"
	local REL_PATH="${PWD#/opt/projects/}"
	if [[ "$PWD" == "/opt/projects/"* ]] && [[ "$REL_PATH" != "" ]]; then
		CONTEXT="${REL_PATH%%/*}"
	fi

	# 2. Determine Git Status
	local GIT_INFO=""
	if command -v git >/dev/null 2>&1; then
		local BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
		if [ -n "$BRANCH" ]; then
			[ "$BRANCH" == "HEAD" ] && BRANCH=$(git rev-parse --short HEAD 2>/dev/null)
			GIT_INFO="${P_GRAY}:${P_WHITE}${BRANCH}"
		fi
	fi

	# 3. Logo & Mode Configuration (Spiral 🌀)
	local MODE_COLOR="${SEGA_ORANGE}" # Default: System (US Style)
	local MODE_TEXT="SYS"

	if [ -f "${HOME}/.kosaio/states/kos_dev" ]; then
		MODE_COLOR="${SEGA_BLUE}"      # Host/Dev (JP/EU Style)
		MODE_TEXT="DEV"
	fi

	# 4. Status Indicator (Power LED 🔻)
	# For unhealthy states we can use a different emoji or just stay red.
	local LED_SYMBOL="🔻"
	[ $EXIT -ne 0 ] && LED_SYMBOL="🛑"

	# Construction: Two-Line HUD (Compact Style)
	# Line 1: 🌀 [CONTEXT:BRANCH : MODE] /path/to/dir
	# Line 2: 🔻 ➜ command
	local LINE1="🌀 ${P_GRAY}[${P_WHITE}${CONTEXT}${GIT_INFO}${P_GRAY} : ${MODE_COLOR}${MODE_TEXT}${P_GRAY}] ${P_PATH}\w${P_RESET}"
	local LINE2="${LED_SYMBOL}  ${MODE_COLOR}➜${P_RESET} "
	
	PS1="\n${LINE1}\n${LINE2}"
}
PROMPT_COMMAND=_kosaio_set_prompt

# --- Updates Check ---
kosaio_check_updates

# --- Welcome Banner ---
# Get KOSAIO versioning
KOSAIO_BRANCH="unknown"
KOSAIO_COMMIT="unknown"
if [ -d "${KOSAIO_DIR}/.git" ]; then
	KOSAIO_BRANCH=$(git -C "${KOSAIO_DIR}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "detached")
	KOSAIO_COMMIT=$(git -C "${KOSAIO_DIR}" rev-parse --short HEAD 2>/dev/null || echo "unknown")
	KOSAIO_DATE=$(git -C "${KOSAIO_DIR}" show -s --format=%cd --date=short HEAD 2>/dev/null || echo "unknown")
fi


# Render the perfectly aligned HUD via Python Engine (Once per session unless forced)
if [ -z "${KOSAIO_BANNER_SHOWN:-}" ]; then
	# Using printf for reliable logo output
	printf "\n"
	printf "  ${C_B_CYAN}██   ██  ██████  ███████  █████  ██  ██████${C_RESET}\n"
	printf "  ${C_B_CYAN}██  ██  ██    ██ ██      ██   ██ ██ ██    ██${C_RESET}\n"
	printf "  ${C_B_CYAN}█████   ██    ██ ███████ ███████ ██ ██    ██${C_RESET}\n"
	printf "  ${C_B_CYAN}██  ██  ██    ██      ██ ██   ██ ██ ██    ██${C_RESET}\n"
	printf "  ${C_B_CYAN}██   ██  ██████  ███████ ██   ██ ██  ██████${C_RESET}\n"
	printf "\n"

	python3 "${KOSAIO_DIR}/scripts/engine/py/main.py" render_banner "${KOSAIO_BRANCH}" "${KOSAIO_COMMIT}" "${KOSAIO_DATE}"
	printf "\n"
	export KOSAIO_BANNER_SHOWN=1
fi
