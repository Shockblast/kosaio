#!/bin/bash
# self_test.sh - Verify SSoT sync between Bash and Python

source "${KOSAIO_DIR}/scripts/common/env.sh"
source "${KOSAIO_DIR}/scripts/common/ui.sh"

ENGINE_PY="${KOSAIO_DIR}/scripts/engine/py/main.py"

function test_path_sync() {
	local tool="$1"
	local bash_path=$(kosaio_get_tool_dir "$tool")
	local python_path=$(python3 "$ENGINE_PY" get_tool_path "$tool" 2>/dev/null)

	if [ "$bash_path" != "$python_path" ]; then
		log_error "SYNC MISMATCH for '$tool': Bash='$bash_path' vs Python='$python_path'"
		return 1
	fi

	log_success "SYNC OK: $tool → $bash_path"
	return 0
}

# Run tests
log_info --draw-line "Running SSoT Synchronization Tests..."
test_path_sync "kos"
test_path_sync "kos-ports"
test_path_sync "flycast"
log_info --draw-line "Tests Completed."
