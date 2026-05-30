#!/bin/bash
# self_test.sh - Verify Python engine (SSoT) is working correctly
# Path resolution is now delegated entirely to Python from Bash.

source "${KOSAIO_DIR}/scripts/common/env.sh"
source "${KOSAIO_DIR}/scripts/common/ui.sh"

ENGINE_PY="${KOSAIO_DIR}/scripts/engine/py/main.py"

function test_python_engine_available() {
	if [ ! -f "$ENGINE_PY" ]; then
		log_error "Python engine not found at $ENGINE_PY"
		return 1
	fi
	if ! command -v python3 >/dev/null 2>&1; then
		log_error "python3 not available"
		return 1
	fi
	log_success "Python engine available"
	return 0
}

function test_path_resolution() {
	local tool="$1"
	local bash_path
	local python_path

	bash_path=$(kosaio_get_tool_dir "$tool")
	python_path=$(python3 "$ENGINE_PY" get_tool_path "$tool" 2>/dev/null) || {
		log_error "Python failed to resolve path for '$tool'"
		return 1
	}

	if [ "$bash_path" != "$python_path" ]; then
		log_error "PATH MISMATCH for '$tool': Bash='$bash_path' vs Python='$python_path'"
		return 1
	fi

	log_success "PATH OK: $tool → $bash_path"
	return 0
}

function test_validate_target() {
	local target="$1"
	local result

	result=$(python3 "$ENGINE_PY" validate_target "$target" 2>/dev/null) || {
		log_info "Validation for '$target' returned non-zero (expected if not installed)"
		return 0
	}
	log_success "Validation OK: $target → $result"
	return 0
}

# Run tests
log_info --draw-line "KOSAIO SSoT Self-Tests"

test_python_engine_available || exit 1
echo ""

log_info "Testing path resolution..."
test_path_resolution "kos"
test_path_resolution "kos-ports"
test_path_resolution "flycast"
echo ""

log_info "Testing target validation..."
test_validate_target "kos"
test_validate_target "system"
echo ""

log_info --draw-line "All self-tests completed."
