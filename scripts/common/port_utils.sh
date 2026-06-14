#!/bin/bash
# scripts/common/port_utils.sh
# Shared utilities for checking KOS-PORTS installation state.

# Note: Port metadata parsing (Makefile) is now delegated to the Python Engine.

# Checks if a port is installed and returns its version
function ports_get_installed_version() {
	local lib_name="$1"
	local version_file="${KOS_PORTS}/lib/.kos-ports/${lib_name}"

	if [ -f "${version_file}" ]; then
		cat "${version_file}"
		return 0
	fi

	# Try canonical name (case-insensitive fs support)
	local resolved
	if resolved=$(ports_resolve_name "${lib_name}" 2>/dev/null) && [ "$resolved" != "$lib_name" ]; then
		local resolved_file="${KOS_PORTS}/lib/.kos-ports/${resolved}"
		if [ -f "${resolved_file}" ]; then
			cat "${resolved_file}"
			return 0
		fi
		local resolved_hash="${KOS_PORTS}/lib/.kos-ports/${resolved}.hash"
		if [ -f "${resolved_hash}" ]; then
			cat "${resolved_hash}"
			return 0
		fi
	fi

	# Fallback: .hash file with input name (legacy)
	local hash_file="${KOS_PORTS}/lib/.kos-ports/${lib_name}.hash"
	if [ -f "${hash_file}" ]; then
		cat "${hash_file}"
		return 0
	fi

	return 1
}

function ports_is_installed() {
	local lib_name="$1"
	if ports_get_installed_version "${lib_name}" >/dev/null 2>&1; then
		return 0
	else
		return 1
	fi
}
