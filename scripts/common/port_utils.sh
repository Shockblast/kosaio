# scripts/common/port_utils.sh
# Shared utilities for checking KOS-PORTS installation state.

# Note: Port metadata parsing (Makefile) is now delegated to the Python Engine.

# Checks if a port is installed and returns its version
function ports_get_installed_version() {
	local lib_name="$1"
	local version_file="${KOS_PORTS_DIR}/lib/.kos-ports/${lib_name}"

	if [ -f "${version_file}" ]; then
		cat "${version_file}"
	else
		return 1
	fi
}

function ports_is_installed() {
	local lib_name="$1"
	if ports_get_installed_version "${lib_name}" >/dev/null 2>&1; then
		return 0
	else
		return 1
	fi
}
