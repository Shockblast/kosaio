#!/bin/bash
# scripts/controllers/dev.sh
# Handles development environment switching (Container vs Host)

function controller_dev_handle() {
	local target="$1"
	local mode="$2"

	if [ -z "$target" ]; then
		log_info --draw-line "Usage: kosaio dev-switch <tool> [container|host|h|c]"
		return
	fi

	local state_file="${HOME}/.kosaio/states/${target}_dev"

	if [ -z "$mode" ]; then
		# Check Status
		if [ -f "$state_file" ]; then
			log_info "${C_BLUE}${target}${C_RESET} is set to ${C_YELLOW}HOST${C_RESET} (Workspace)."
		else
			log_info "${C_BLUE}${target}${C_RESET} is set to ${C_CYAN}CONTAINER${C_RESET} (System)."
		fi
		return
	fi

	mkdir -p "$(dirname "$state_file")"

	case "${mode,,}" in
		"host"|"h"|"workspace"|"enable")
			touch "$state_file"
			log_success "${C_BLUE}${target}${C_RESET} switched to ${C_YELLOW}HOST${C_RESET} mode."
			;;
		"container"|"c"|"system"|"disable")
			rm -f "$state_file"
			log_success "${C_BLUE}${target}${C_RESET} switched to ${C_CYAN}CONTAINER${C_RESET} mode."
			;;
		*)
			log_error "Mode '${mode}' unknown. Use 'c' or 'h'."
			;;
	esac
}
