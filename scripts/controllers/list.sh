#!/bin/bash
# scripts/controllers/list.sh
# Handles list and search operations

function controller_list_handle() {
	# Extract query if present (argument not starting with -)
	local query=""
	for arg in "$@"; do
		[[ "$arg" != -* ]] && query="$arg"
	done

	if [ -n "$query" ]; then
		log_info --draw-line "Search Results for: ${C_YELLOW}${query}${C_RESET}"
	else
		log_info --draw-line "KOSAIO Registry Status"
	fi

	search_execute "$@"
	echo ""
}
