#!/bin/bash
# scripts/common/completions.sh
# Bash completion for KOSAIO

__KOSAIO_CACHE_DIR="${TMPDIR:-/tmp}/kosaio-completions"
__KOSAIO_CACHE_FILE="${__KOSAIO_CACHE_DIR}/targets"
__KOSAIO_CACHE_TTL=60  # seconds

function _kosaio_build_target_cache() {
	local python_engine="${KOSAIO_DIR}/scripts/engine/py/main.py"
	if [ ! -f "$python_engine" ] || ! command -v python3 >/dev/null 2>&1; then
		return 1
	fi
	mkdir -p "$__KOSAIO_CACHE_DIR" 2>/dev/null || return 1
	python3 "$python_engine" update_cache 2>/dev/null | cut -d'|' -f1 > "$__KOSAIO_CACHE_FILE"
}

function _kosaio_get_targets() {
	local cache_age
	if [ -f "$__KOSAIO_CACHE_FILE" ]; then
		local now mtime
		now=$(date +%s)
		mtime=$(stat -c %Y "$__KOSAIO_CACHE_FILE" 2>/dev/null || echo 0)
		cache_age=$(( now - mtime ))
		if [ "$cache_age" -lt "$__KOSAIO_CACHE_TTL" ]; then
			cat "$__KOSAIO_CACHE_FILE" 2>/dev/null
			return
		fi
	fi
	_kosaio_build_target_cache
	cat "$__KOSAIO_CACHE_FILE" 2>/dev/null
}

function _kosaio_completions() {
	local cur prev opts targets
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"

	# Main actions (Updated to match driver_manager capabilities)
	opts="list search dev-switch create-project self-update info install uninstall update diagnose apply build"

	# Dynamic Target Discovery via Python Engine (cached)
	targets=$(_kosaio_get_targets)

	case "${prev}" in
		kosaio)
			mapfile -t COMPREPLY < <(compgen -W "${opts}" -- "${cur}")
			return 0
			;;
		dev-switch|install|uninstall|update|diagnose|apply|build|info|clone|checkout|reset|clean)
			mapfile -t COMPREPLY < <(compgen -W "${targets}" -- "${cur}")
			return 0
			;;
		list|search)
			if [[ "${cur}" == -* ]]; then
				mapfile -t COMPREPLY < <(compgen -W "--installed -i" -- "${cur}")
			else
				mapfile -t COMPREPLY < <(compgen -W "${targets}" -- "${cur}")
			fi
			return 0
			;;
	esac

	# Sub-options for dev-switch
	if [[ ${COMP_CWORD} -eq 3 && ${COMP_WORDS[1]} == "dev-switch" ]]; then
		mapfile -t COMPREPLY < <(compgen -W "host container" -- "${cur}")
		return 0
	fi
}

# Quick Project Jump
	function kcd() {
	if [ -z "$1" ]; then
		cd /opt/projects || return 1
	else
		cd "/opt/projects/$1" || return 1
	fi
}

function _kcd_completions() {
	local cur projects
	cur="${COMP_WORDS[COMP_CWORD]}"
	projects=$(find /opt/projects -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null | xargs -0 -n1 basename)
	mapfile -t COMPREPLY < <(compgen -W "${projects}" -- "${cur}")
}

# Register completions
complete -F _kosaio_completions kosaio
complete -F _kcd_completions kcd
