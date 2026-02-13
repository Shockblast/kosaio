#!/bin/bash
# scripts/commands/tool.sh
# KOSAIO Utility Wrapper specific to Dreamcast SDK tools

function kosaio_cmd_tool() {
	local tool_name="${1:-}"
	shift || true # Shift tool name, keep args
	
	if [ -z "$tool_name" ]; then
		log_error "Usage: kosaio tool <utility_name> [args...]"
		log_info "Available tools: pvrtex, scramble, dcbumpgen, bin2c"
		return 1
	fi

	# 1. Check if KOS is installed (Base Requirement)
	if [ -z "${KOS_BASE:-}" ] || [ ! -d "${KOS_BASE}" ]; then
		# Try to source environment if not loaded
		if [ -f "${DREAMCAST_SDK}/kos/environ.sh" ]; then
			source "${DREAMCAST_SDK}/kos/environ.sh"
		else
			log_box --type=error "SDK MISSING" \
				"The 'tool' command requires KOS utilities." \
				"Please install the SDK Core first:" \
				"${C_CYAN}kosaio install kos${C_RESET}"
			return 1
		fi
	fi

	# 2. Map aliases to actual paths
	local bin_path=""
	
	case "$tool_name" in
		"pvrtex"|"texconv")
			# pvrtex might be in utils/pvrtex/ or utils/texconv/ depending on version
			if [ -f "${KOS_BASE}/utils/pvrtex/pvrtex" ]; then
				bin_path="${KOS_BASE}/utils/pvrtex/pvrtex"
			elif [ -f "${KOS_BASE}/utils/texconv/texconv" ]; then
				bin_path="${KOS_BASE}/utils/texconv/texconv"
			fi
			;;
		"scramble")
			bin_path="${KOS_BASE}/utils/scramble/scramble"
			;;
		"makeip")
			bin_path="${KOS_BASE}/utils/makeip/makeip"
			;;
		"vqenc")
			bin_path="${KOS_BASE}/utils/vqenc/vqenc"
			;;
		"wav2adpcm")
			bin_path="${KOS_BASE}/utils/wav2adpcm/wav2adpcm"
			;;
		"bin2o")
			bin_path="${KOS_BASE}/utils/bin2o/bin2o"
			;;
		"kmgenc")
			bin_path="${KOS_BASE}/utils/kmgenc/kmgenc"
			;;
		"dcbumpgen") # Bump map generator
			bin_path="${KOS_BASE}/utils/dcbumpgen/dcbumpgen"
			;;
		"bin2c")
			bin_path="${KOS_BASE}/utils/bin2c/bin2c"
			;;
		"genromfs")
			bin_path="${KOS_BASE}/utils/genromfs/genromfs"
			;;
		*)
			log_error "Unknown tool: '$tool_name'"
			log_info "Available: pvrtex, scramble, makeip, vqenc, wav2adpcm, bin2o, bin2c"
			return 127
			;;
	esac

	# 3. Verify Binary Existence
	if [ ! -f "$bin_path" ]; then
		log_error "Tool binary not found: $bin_path"
		log_info "Try rebuilding KOS utils: ${C_CYAN}kosaio build kos${C_RESET}"
		return 1
	fi
	
	if [ ! -x "$bin_path" ]; then
		chmod +x "$bin_path"
	fi

	# 4. Execute
	# We run in a subshell to avoid polluting current env, but sharing stdout/err
	log_info "Running ${tool_name}..."
	"$bin_path" "$@"
}
