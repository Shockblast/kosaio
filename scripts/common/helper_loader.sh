#!/bin/bash
# scripts/common/helper_loader.sh
# Loads tool-specific hooks from scripts/registry/hooks/ when needed.

kosaio_load_tool_helpers() {
	local tool_id="${1:?}"
	local hook="${KOSAIO_DIR}/scripts/registry/hooks/${tool_id}.sh"

	if [ -f "$hook" ]; then
		# shellcheck disable=SC1090
		source "$hook"
		return 0
	fi

	# Fallback: try generic base name (e.g. sdl2-dc -> sdl)
	local base="${tool_id%%[0-9]*}"
	local fallback="${KOSAIO_DIR}/scripts/registry/hooks/${base}.sh"
	if [ "$base" != "$tool_id" ] && [ -f "$fallback" ]; then
		# shellcheck disable=SC1090
		source "$fallback"
	fi
}
