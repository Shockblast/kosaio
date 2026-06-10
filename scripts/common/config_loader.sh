#!/bin/bash
# scripts/common/config_loader.sh
# Loads tool-specific metadata from scripts/registry/tools/<tool-id>.tool

set -Eeuo pipefail

function kosaio_load_tool_config() {
    local tool_id="$1"
    local config_path="${KOSAIO_DIR}/scripts/registry/tools/${tool_id}.tool"

    if [ ! -f "$config_path" ]; then
        log_error "Metadata not found for '${tool_id}'."
        log_info "Expected: ${config_path}"
        log_info "Run 'kosaio config ${tool_id} --meta' to edit it."
        return 1
    fi

    # shellcheck disable=SC1090
    source "$config_path"
    return 0
}
