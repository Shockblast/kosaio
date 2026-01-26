#!/bin/bash
# scripts/engine/ports/utils.sh

function ports_resolve_name() {
	local input_name="$1"

	# Delegate to Python Engine
	if resolved_name=$(python3 "${KOSAIO_DIR}/scripts/engine/py/main.py" resolve_port_name "${input_name}" 2>/dev/null); then
		echo "${resolved_name}"
		return 0
	else
		return 1
	fi
}

function _ports_snapshot() {
	local file="$1"
	# Snapshot relevant directories, including KOS_PORTS symlinks
	find "${KOS_BASE}/lib" "${KOS_BASE}/include" "${KOS_BASE}/addons" \
		 "${KOS_PORTS_DIR}/lib" "${KOS_PORTS_DIR}/include" \
		 \( -type f -o -type l \) 2>/dev/null | sort > "${file}"
}

function _ports_validate_library() {
	local lib_name="$1"
	if ports_resolve_name "${lib_name}" >/dev/null; then
		return 0
	fi
	return 1
}

function _ports_print_summary() {
	local operation="$1"
	shift
	local success_libs=("$@")
	local success_count=${#success_libs[@]}

	if [ $success_count -gt 0 ]; then
		echo ""
		echo "${operation} Summary:"
		echo "Successful: $success_count"
		for lib in "${success_libs[@]}"; do
			echo "  ✓ ${lib}"
		done
	fi
}
