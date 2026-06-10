#!/bin/bash
set -Eeuo pipefail
# driver_refresh.sh - Reconcile .kosaio_installed markers with actual filesystem state

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
			kosaio_reg_reconcile_marker "$id" && ((updated++)) || ((fixed++))
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

	local marker="$tool_dir/.kosaio_installed"

	# Load KOSAIO_TOOL_LIBS from the .tool file via Python or bash
	python3 "$ENGINE_PY" get_manifest_path "$id" 2>/dev/null | head -1 | while read -r manifest; do
		[ -f "$manifest" ] && source "$manifest"
	done 2>/dev/null

	if [ ! -d "$tool_dir" ]; then
		rm -f "$marker"
		return 1
	fi

	# Check if any KOSAIO_TOOL_LIBS exist
	local found=0
	for lib in "${KOSAIO_TOOL_LIBS[@]}"; do
		[ -f "$lib" ] && { found=1; break; }
	done

	if [ "$found" -eq 1 ]; then
		touch "$marker"
		log_info "${id}: ${C_GREEN}healthy${C_RESET}"
		return 0
	else
		rm -f "$marker"
		log_info "${id}: ${C_YELLOW}not compiled${C_RESET}"
		return 1
	fi
}
