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

# --- Navigation Aliases ---
alias ksdk='cd /opt/toolchains/dc'
alias kkos='cd ${KOS_BASE}'
alias kports='cd ${KOS_PORTS_DIR}'
alias kproj='cd /opt/projects'
alias reload='unset KOSAIO_BANNER_SHOWN; source ${KOSAIO_DIR}/scripts/shell-init.sh'

# --- Dynamic Prompt (PS1) ---
# Contextual prompt: [CONTEXT(:BRANCH) : MODE] /path/to/dir #
function _kosaio_set_prompt() {
	local EXIT="$?"
	# PS1 requires \[ \] wrappers for non-printing characters
	local P_RESET="\[${ESC}[0m\]"
	local P_GRAY="\[${ESC}[0;90m\]"
	local P_MAGENTA="\[${ESC}[1;35m\]"
	local P_BLUE="\[${ESC}[1;34m\]"
	local P_CYAN="\[${ESC}[1;36m\]"
	local P_GREEN="\[${ESC}[1;32m\]"
	local P_RED="\[${ESC}[1;31m\]"
	local P_YELLOW="\[${ESC}[1;33m\]"

	# 1. Determine Context (Project Awareness)
	local CONTEXT="KOS"
	# Remove /opt/projects/ prefix if present
	local REL_PATH="${PWD#/opt/projects/}"

	# If we are effectively inside /opt/projects (and not just at the root of it)
	if [[ "$PWD" == "/opt/projects/"* ]] && [[ "$REL_PATH" != "" ]]; then
		# Extract the first directory component as the project name
		CONTEXT="${REL_PATH%%/*}"
	fi

	# 2. Determine Git Status
	local GIT_INFO=""
	if command -v git >/dev/null 2>&1; then
		local BRANCH
		if BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null); then
			if [ "$BRANCH" == "HEAD" ]; then
				BRANCH=$(git rev-parse --short HEAD 2>/dev/null)
			fi
			GIT_INFO="${P_GRAY}:${P_CYAN}${BRANCH}"
		fi
	fi

	# 3. Status Configuration
	local MODE_COLOR="${P_GREEN}"      # Green for Container
	local MODE_TEXT="SYS"              # Shortened from CONTAINER to save space

	if [ -f "${HOME}/.kosaio/states/kos_dev" ]; then
		MODE_COLOR="${P_YELLOW}"       # Yellow for Host
		MODE_TEXT="DEV"                # Shortened from HOST/WORKSPACE
	elif [ "$CONTEXT" == "KOS" ]; then
		MODE_TEXT="SYS"
	else
		# If we are in a project, the 'Environment' is what matters (Container vs Host libs)
		MODE_TEXT="ENV"
	fi

	# Check specific override again to be sure (UI consistency)
	if [ -f "${HOME}/.kosaio/states/kos_dev" ]; then
		MODE_TEXT="DEV"
	else
		MODE_TEXT="SYS"
	fi

	# Prompt Character (Signal Error)
	local PROMPT_CHAR="${P_GREEN}➜${P_RESET}"
	[ $EXIT -ne 0 ] && PROMPT_CHAR="${P_RED}➜${P_RESET}"

	# Construction: 2-Line Prompt (OMZ Style)
	# Line 1: [ CONTEXT : BRANCH ] path
	# Line 2: ➜ input
	PS1="${P_GRAY}[${P_MAGENTA}${CONTEXT}${GIT_INFO}${P_GRAY}:${MODE_COLOR}${MODE_TEXT}${P_GRAY}] ${P_BLUE}\w${P_RESET}\n${PROMPT_CHAR} "
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


# Using printf for reliable logo output
printf "\n"
printf "  ${C_B_CYAN}██   ██  ██████  ███████  █████  ██  ██████${C_RESET}\n"
printf "  ${C_B_CYAN}██  ██  ██    ██ ██      ██   ██ ██ ██    ██${C_RESET}\n"
printf "  ${C_B_CYAN}█████   ██    ██ ███████ ███████ ██ ██    ██${C_RESET}\n"
printf "  ${C_B_CYAN}██  ██  ██    ██      ██ ██   ██ ██ ██    ██${C_RESET}\n"
printf "  ${C_B_CYAN}██   ██  ██████  ███████ ██   ██ ██  ██████${C_RESET}\n"
printf "\n"

# Render the perfectly aligned HUD via Python Engine (Once per session unless forced)
if [ -z "${KOSAIO_BANNER_SHOWN:-}" ]; then
	python3 "${KOSAIO_DIR}/scripts/engine/py/main.py" render_banner "${KOSAIO_BRANCH}" "${KOSAIO_COMMIT}" "${KOSAIO_DATE}"
	printf "\n"
	export KOSAIO_BANNER_SHOWN=1
fi
