#!/bin/bash
set -Eeuo pipefail
# driver_refresh.sh - Reconcile install markers with actual filesystem state
# Writes data/states/container/<tool> when KOSAIO_TOOL_LIBS are present.

# shellcheck source=../common/state.sh
source "${KOSAIO_DIR}/scripts/common/state.sh" 2>/dev/null || \
	source "$(dirname "${BASH_SOURCE[0]}")/../common/state.sh" 2>/dev/null || true

ENGINE_PY="${KOSAIO_DIR}/scripts/engine/py/main.py"

function kosaio_refresh() {
	local target="${1:-}"

	if [ -n "$target" ] && [ "$target" != "all" ]; then
		kosaio_refresh_single "$target"
		return $?
	fi

	log_info --draw-line "Refreshing all tool markers..."

	local updated=0
	local fixed=0
	local tool_dir

	for tool_file in "${KOSAIO_DIR}/scripts/registry/tools/"*.tool; do
		local id
		id=$(basename "$tool_file" .tool)

		if [ -f "$tool_file" ]; then
			kosaio_load_tool_config "$id" 2>/dev/null || continue
			if kosaio_reg_reconcile_marker "$id"; then
				updated=$((updated + 1))
			else
				fixed=$((fixed + 1))
			fi
		fi
	done

	log_success "Refresh complete: ${updated} healthy, ${fixed} corrected."
}

function kosaio_refresh_single() {
	local id="$1"
	kosaio_load_tool_config "$id" 2>/dev/null || {
		log_error "Tool '${id}' not found in registry."
		return 1
	}
	kosaio_reg_reconcile_marker "$id"
}

function kosaio_reg_reconcile_marker() {
	local id="$1"
	# Use env.sh fallback resolution which now points to data/repos/
	local tool_dir
	tool_dir=$(kosaio_get_tool_dir "$id" 2>/dev/null) || {
		log_warn "Cannot resolve directory for '${id}'. Skipping."
		return 2
	}

	# Load KOSAIO_TOOL_LIBS from the .tool file via Python or bash
	python3 "$ENGINE_PY" get_manifest_path "$id" 2>/dev/null | head -1 | while read -r manifest; do
		[ -f "$manifest" ] && source "$manifest"
	done 2>/dev/null

	if [ ! -d "$tool_dir" ]; then
		kosaio_state_unset container "$id" 2>/dev/null || true
		return 1
	fi

	# Check if any KOSAIO_TOOL_LIBS exist
	local found=0
	for lib in "${KOSAIO_TOOL_LIBS[@]}"; do
		[ -f "$lib" ] && { found=1; break; }
	done

	if [ "$found" -eq 1 ]; then
		kosaio_state_set container "$id" 2>/dev/null || true
		log_info "${id}: ${C_GREEN}healthy${C_RESET}"
		return 0
	else
		kosaio_state_unset container "$id" 2>/dev/null || true
		log_info "${id}: ${C_YELLOW}not compiled${C_RESET}"
		return 1
	fi
}
