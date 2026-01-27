#!/bin/bash

# scripts/common/kos_pivot.sh
# This script handles the switching of KOS environment variables between 
# Container and Host modes. It should be SOURCED, not executed.

function kosaio_kos_pivot() {
	# 1. Load current environment rules
	source "${KOSAIO_DIR}/scripts/common/env.sh" > /dev/null

	local target_environ="${KOS_DIR}/environ.sh"

	# 2. DEEP CLEANUP: Reset all KOS-related variables before switching
	# Standard KOS variables
	unset KOS_BASE KOS_ARCH KOS_SUBARCH KOS_PORTS KOS_MAKE KOS_LOADER KOS_GENROMFS KOS_STRIP
	unset KOS_CC_BASE KOS_CC_PREFIX KOS_AS KOS_AR KOS_OBJCOPY KOS_LD
	unset KOS_CFLAGS KOS_CPPFLAGS KOS_LDFLAGS KOS_AFLAGS KOS_INC_PATHS
	unset DC_ARM_BASE DC_ARM_PREFIX DC_ARM_LDFLAGS

	# Path Cleanup (Remove previous toolchains and dev workspace from PATH)
	local CLEAN_PATH=$(echo "$PATH" | tr ":" "\n" | grep -v "toolchains" | grep -v "kosaio-dev" | tr "\n" ":" | sed 's/:$//')
	export PATH="${CLEAN_PATH}"

	# 3. Check if the target environment exists
	if [ ! -f "${target_environ}" ]; then
		log_error "KOS Environment not found at: ${target_environ}"
		local current_mode="CONTAINER (System)"
		[ -f "${HOME}/.kosaio/states/kos_dev" ] && current_mode="HOST (Workspace)"
		log_info "Current Mode: ${current_mode}"
		log_info "Next step: kosaio clone|install kos"
		return 1
	fi

	# 4. Source the environment
	# Standard KOS environ.sh will populate PATH and variables
	source "${target_environ}" > /dev/null 2>&1

	# 5. Re-inject KOSAIO Extras Bin (it might have been wiped by cleanup)
	if [ -d "${DREAMCAST_BIN_PATH:-}" ]; then
		export PATH="${PATH}:${DREAMCAST_BIN_PATH}"
	fi

	# 6. Success Message
	if [ "$KOSAIO_DEV_MODE" == "1" ] || [ -f "${HOME}/.kosaio/states/kos_dev" ]; then
		log_success "KOS Environment pivoted to: ${C_YELLOW}HOST (Workspace)${C_RESET}"
		log_info "Path: ${KOS_DIR}"
	else
		log_success "KOS Environment pivoted to: ${C_GREEN}CONTAINER (System)${C_RESET}"
		log_info "Path: ${KOS_DIR}"
	fi
}

# Alias for easy access
alias kos-env='kosaio_kos_pivot'
alias kenv='kosaio_kos_pivot'
