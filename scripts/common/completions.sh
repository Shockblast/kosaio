# scripts/common/completions.sh
# Bash completion for KOSAIO

function _kosaio_completions() {
	local cur prev opts targets
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"

	# Main actions (Updated to match driver_manager capabilities)
	opts="list search dev-switch create-project self-update info install uninstall update diagnose apply build"

	# Dynamic Target Discovery via Python Engine (Fast)
	# We fetch both Registry Tools and Ports
	local python_engine="${KOSAIO_DIR}/scripts/engine/py/main.py"
	if [ -f "$python_engine" ] && command -v python3 >/dev/null 2>&1; then
		# Using 'update_cache' internally just to dump the list raw
		targets=$(python3 "$python_engine" update_cache 2>/dev/null | cut -d'|' -f1)
	fi

	case "${prev}" in
		kosaio)
			COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
			return 0
			;;
		dev-switch|install|uninstall|update|diagnose|apply|build|info|clone|checkout|reset|clean)
			COMPREPLY=( $(compgen -W "${targets}" -- ${cur}) )
			return 0
			;;
	esac

	# Sub-options for dev-switch
	if [[ ${COMP_CWORD} -eq 3 && ${COMP_WORDS[1]} == "dev-switch" ]]; then
		COMPREPLY=( $(compgen -W "host container" -- ${cur}) )
		return 0
	fi
}

# Quick Project Jump
function kcd() {
	if [ -z "$1" ]; then
		cd /opt/projects
	else
		cd "/opt/projects/$1"
	fi
}

function _kcd_completions() {
	local cur projects
	cur="${COMP_WORDS[COMP_CWORD]}"
	projects=$(ls -d /opt/projects/*/ 2>/dev/null | xargs -n1 basename)
	COMPREPLY=( $(compgen -W "${projects}" -- ${cur}) )
}

# Register completions
complete -F _kosaio_completions kosaio
complete -F _kcd_completions kcd
