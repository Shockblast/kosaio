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

	# Strict Validation: Ensure target is a known tool/port
	if ! python3 "${KOSAIO_DIR}/scripts/engine/py/main.py" validate_target "$target" >/dev/null 2>&1; then
		log_error "Target '${target}' is not a valid KOSAIO tool or port."
		return 1
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
		"host"|"h"|"workspace"|"enable"|"dev")
			# Validation: Check if the target exists in the workspace
			local workspace_path="${KOSAIO_DEV_ROOT}/${target}"
			if [ ! -d "${workspace_path}" ]; then
				log_error "Target '${target}' not found in workspace: ${workspace_path}"
				log_info "Tip: Run 'kosaio clone ${target}' or 'kosaio install ${target}' first."
				return 1
			fi

			touch "$state_file"
			log_success "${C_BLUE}${target}${C_RESET} switched to ${C_YELLOW}HOST${C_RESET} mode."
			;;
		"container"|"c"|"system"|"disable"|"cont"|"sys")
			rm -f "$state_file"
			log_success "${C_BLUE}${target}${C_RESET} switched to ${C_CYAN}CONTAINER${C_RESET} mode."
			;;
		*)
			log_error "Mode '${mode}' unknown. Use 'c' or 'h'."
			;;
	esac
}
