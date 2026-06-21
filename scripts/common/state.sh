#!/bin/bash
# scripts/common/state.sh
# Centralized state management for kosaio tools.
#
# State files live in ${KOSAIO_STATE_DIR} (default: ${KOSAIO_DIR}/data/states).
# Organized by scope (subdir):
#   container/<tool>  → kosaio successfully built/installed this tool in the container
#   host/<tool>       → user activated `kosaio dev <tool> host` (workspace mode)
#   broken/<tool>     → install attempt failed, requires re-running

# --- Paths ---

: "${KOSAIO_STATE_DIR:=${KOSAIO_DIR:-/opt/kosaio}/data/states}"
export KOSAIO_STATE_DIR
export KOSAIO_STATE_SCOPES=(container host broken)

# --- Helpers ---

# kosaio_state_set <scope> <tool>
# Creates the marker file for a tool in a given scope.
kosaio_state_set() {
	local scope="$1"
	local tool="$2"
	if [ -z "$scope" ] || [ -z "$tool" ]; then
		echo "kosaio_state_set: missing scope or tool" >&2
		return 1
	fi
	mkdir -p "${KOSAIO_STATE_DIR}/${scope}"
	touch "${KOSAIO_STATE_DIR}/${scope}/${tool}"
}

# kosaio_state_unset <scope> <tool>
# Removes the marker file for a tool in a given scope.
kosaio_state_unset() {
	local scope="$1"
	local tool="$2"
	if [ -z "$scope" ] || [ -z "$tool" ]; then
		echo "kosaio_state_unset: missing scope or tool" >&2
		return 1
	fi
	rm -f "${KOSAIO_STATE_DIR}/${scope}/${tool}"
}

# kosaio_state_get <scope> <tool>
# Returns 0 if marker exists, 1 otherwise.
kosaio_state_get() {
	local scope="$1"
	local tool="$2"
	if [ -z "$scope" ] || [ -z "$tool" ]; then
		return 1
	fi
	[ -f "${KOSAIO_STATE_DIR}/${scope}/${tool}" ]
}

# kosaio_state_list <scope>
# Lists all tools in a given scope (one per line).
kosaio_state_list() {
	local scope="$1"
	if [ -z "$scope" ] || [ ! -d "${KOSAIO_STATE_DIR}/${scope}" ]; then
		return 0
	fi
	ls -1 "${KOSAIO_STATE_DIR}/${scope}/" 2>/dev/null
}
