#!/bin/bash
# scripts/common/update_check.sh
# Checks for updates periodically (OMZ style)

function kosaio_check_updates() {
	[ "${KOSAIO_DISABLE_UPDATE_CHECK:-0}" = "1" ] && return 0

	local update_file="${HOME}/.kosaio/last_update_check"
	local epoch_target=0

	# Ensure state directory exists
	mkdir -p "$(dirname "$update_file")"

	# Check timestamp
	if [ -f "$update_file" ]; then
		local last_check
		last_check=$(cat "$update_file")
		local current_time
		current_time=$(date +%s)
		
		# 24 hours = 86400 seconds
		epoch_target=$((last_check + 86400))
		
		if [ "$current_time" -lt "$epoch_target" ]; then
			return 0
		fi
	fi

	# Perform Check
	# Run in subshell to avoid changing CWD
	(
		cd "${KOSAIO_DIR}" || exit 0
		
		# Check if it's a git repo
		[ -d ".git" ] || exit 0
		
		# If branch is HEAD (detached), we don't notify
		[ "${KOSAIO_BRANCH}" = "HEAD" ] && exit 0

		# Fetch updates for the core branch
		git fetch origin "${KOSAIO_BRANCH}" --quiet 2>/dev/null

		local local_rev
		local_rev=$(git rev-parse HEAD)
		local remote_rev
		remote_rev=$(git rev-parse "origin/${KOSAIO_BRANCH}" 2>/dev/null)
		
		if [ -n "$remote_rev" ]; then
			local base_rev
			base_rev=$(git merge-base HEAD "origin/${KOSAIO_BRANCH}" 2>/dev/null)

			if [ "$local_rev" != "$remote_rev" ] && [ "$local_rev" = "$base_rev" ]; then
				# We are behind!
				# Use direct colors since this runs in subshell, might miss ui.sh scope if not careful, 
				# but ui.sh exports globally so it should be fine.
				# Using raw ANSI just in case.
				printf "\n"
				printf "\033[1;33m[KOSAIO] \033[1;36mUpdate available!\033[0m\n"
				printf "\033[0;90mRun \033[1;33mkosaio self-update\033[0;90m to upgrade.\033[0m\n"
				printf "\n"
			fi
		fi
	)
	# Run synchronously to ensure message visibility before banner
	# Git fetch can be slow. OMZ asyncs it.
	# But wait, if we background it, the message might pop up in the middle of typing.
	# Let's run synchronously but with a timeout or just accept the fetch time (usually fast).
	# For now, synchronous to ensure message visibility at startup.
	
	# Update timestamp
	date +%s > "$update_file"
}
