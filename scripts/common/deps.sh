#!/bin/bash

# scripts/common/deps.sh
# Centralized dependency management for KOSAIO.

# Checks if a list of APT packages are installed.
# Returns 0 if all installed, 1 if any missing.
function kosaio_check_apt_deps() {
	local missing=0
	for pkg in "$@"; do
		if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
			missing=1
			break
		fi
	done

	return $missing
}

# Installs missing APT packages.
function kosaio_install_apt_deps() {
	local missing=()
	for pkg in "$@"; do
		if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
			missing+=("$pkg")
		fi
	done

	if [[ ${#missing[@]} -gt 0 ]]; then
		log_info "Installing system dependencies: ${missing[*]}"
		apt-get update -qq
		apt-get install -y -qq "${missing[@]}"
	fi
}

# Installs the Core SDK dependencies (GCC, Make, etc.)
function kosaio_install_core_sdk_deps() {
	local deps_file="${KOSAIO_DIR}/scripts/common/core_deps.txt"

	if [ ! -f "$deps_file" ]; then
		log_error "Core dependencies file not found: $deps_file"
		return 1
	fi

	log_info --draw-line "Installing KOSAIO Master dependencies from file..."

	# Parse file: remove comments, remove empty lines, and join into a single line
	local deps=$(grep -v '^#' "$deps_file" | grep -v '^$' | xargs)

	if [ -n "$deps" ]; then
		kosaio_install_apt_deps $deps
		log_success "All master dependencies are installed."
	else
		log_warn "Dependency file is empty."
	fi
}
