#!/bin/bash
# scripts/common/update_check.sh
# Checks for updates periodically (OMZ style)

function kosaio_check_updates() {
	[ "${KOSAIO_DISABLE_UPDATE_CHECK:-0}" = "1" ] && return 0

	# 1. Identify current context
	local current_branch
	current_branch=$(git -C "${KOSAIO_DIR}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")
	
	# Skip if detached HEAD
	[ "${current_branch}" = "HEAD" ] && return 0

	local update_file="${HOME}/.kosaio/last_update_check_${current_branch}"
	local epoch_target=0

	# Ensure state directory exists
	mkdir -p "$(dirname "$update_file")"

	# 2. Check cached timestamp (24h as a reasonable default, but we check branch change)
	if [ -f "$update_file" ]; then
		local last_check=$(cat "$update_file")
		local current_time=$(date +%s)
		
		# 24 hours = 86400 seconds
		epoch_target=$((last_check + 86400))
		
		if [ "$current_time" -lt "$epoch_target" ]; then
			return 0
		fi
	fi

	# 3. Fast Remote Check via ls-remote (only reads headers, no full fetch)
	(
		cd "${KOSAIO_DIR}" || exit 0
		
		local local_rev=$(git rev-parse HEAD 2>/dev/null)
		local remote_rev
		
		# Get remote HEAD for the current branch
		remote_rev=$(git ls-remote --heads origin "${current_branch}" 2>/dev/null | awk '{print $1}')
		
		if [ -z "$remote_rev" ]; then
			# Error or network down, just silently exit and wait 1 hour for next check
			echo $(( $(date +%s) - 86400 + 3600 )) > "$update_file"
			exit 0
		fi

		if [ "$local_rev" != "$remote_rev" ]; then
			# DOUBLE CHECK: only notify if we are strictly behind
			# (using merge-base would require a fetch, so we just check inequality for now
			# as we assume users won't force-push ahead of origin on managed branches usually)
			
			printf "\n"
			printf "  ${C_B_YELLOW}[KOSAIO] ${C_B_CYAN}Update available in branch ${current_branch}!${C_RESET}\n"
			printf "  ${C_GRAY}Run ${C_YELLOW}kosaio update self${C_GRAY} to see the changelog and upgrade.${C_RESET}\n"
			printf "\n"
		fi
		
		# Update timestamp
		date +%s > "$update_file"
	)
}
