#!/bin/bash
# scripts/common/helper_loader.sh
# Loads tool-specific helper scripts from configs/tools/helpers/ when needed.

kosaio_load_tool_helpers() {
	local tool_id="${1:?}"
	local helper="${KOSAIO_DIR}/configs/tools/helpers/${tool_id}.sh"

	if [ -f "$helper" ]; then
		source "$helper"
		return 0
	fi

	# Fallback: try generic base name (e.g. sdl2-dc -> sdl)
	local base="${tool_id%%[0-9]*}"
	local fallback="${KOSAIO_DIR}/configs/tools/helpers/${base}.sh"
	if [ "$base" != "$tool_id" ] && [ -f "$fallback" ]; then
		source "$fallback"
	fi
}
