#!/bin/bash
# scripts/common/kos_env.sh
# Resolves and sources the generated KOS environment file across
# KallistiOS layouts (v2.2.x and master/3.x).
#
# The generated file is `environ.sh` on every upstream branch today, but its
# location helpers and the sample it is built from vary by branch, so callers
# must not hardcode the filename. A future `environment.sh` rename is also
# accepted defensively.

# Prints the first existing candidate (<dir>/environ.sh, <dir>/environment.sh).
# Returns 1 when no candidate exists. Defaults to ${KOS_DIR}.
function kosaio_kos_find_env_file() {
	local kos_dir="${1:-${KOS_DIR:-}}"
	local candidate
	for candidate in "environ.sh" "environment.sh"; do
		if [ -n "$kos_dir" ] && [ -f "${kos_dir}/${candidate}" ]; then
			echo "${kos_dir}/${candidate}"
			return 0
		fi
	done
	return 1
}

# Sources the resolved KOS environment file in the current shell and exports
# its path as KOSAIO_KOS_ENV_FILE. Returns 1 when no candidate exists.
function kosaio_kos_source_env() {
	local env_file
	env_file="$(kosaio_kos_find_env_file "${1:-}")" || return 1
	# shellcheck source=/dev/null
	source "$env_file"
	export KOSAIO_KOS_ENV_FILE="$env_file"
	return 0
}
