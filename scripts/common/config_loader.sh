#!/bin/bash
# scripts/common/config_loader.sh
# Loads tool-specific configuration from configs/tools/<tool-id>.conf

set -Eeuo pipefail

function kosaio_load_tool_config() {
    local tool_id="$1"
    local config_path="${KOSAIO_DIR}/configs/tools/${tool_id}.conf"

    if [ ! -f "$config_path" ]; then
        log_error "Configuration not found for '${tool_id}'."
        log_info "Expected: ${config_path}"
        log_info "Run 'kosaio config ${tool_id}' to create one."
        return 1
    fi

    source "$config_path"
    return 0
}
