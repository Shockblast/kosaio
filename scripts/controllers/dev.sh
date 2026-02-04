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
	local target_type
	target_type=$(python3 "${KOSAIO_DIR}/scripts/engine/py/main.py" get_type "$target")
	
	if [ -z "$target_type" ] || [ "$target_type" == "unknown" ]; then
		log_error "Target '${target}' is not a valid KOSAIO tool or port."
		return 1
	fi

	# ARCHITECTURE DECISION: Ports are a collection.
	# We only allow dev-switch for 'kos-ports' as a whole, not individual ports.
	if [ "$target_type" == "port" ] && [ "$target" != "kos-ports" ]; then
		log_warn "Individual port '${target}' cannot be switched independently."
		log_info "To use host ports, run: ${C_CYAN}kosaio dev-switch kos-ports host${C_RESET}"
		return 1
	fi

	# Resolve canonical name (for case-insensitive support in ports)
	# ports_resolve_name is available if ports driver is loaded
	if [ "$(type -t ports_resolve_name)" == "function" ]; then
		if resolved=$(ports_resolve_name "$target"); then
			target="$resolved"
		fi
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
			# Use the engine to get the authoritative path for host mode
			local workspace_path
			workspace_path=$(python3 "${KOSAIO_DIR}/scripts/engine/py/main.py" get_tool_path "$target" --mode dev)
			
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
