#!/bin/bash
# scripts/engine/ports/core.sh

function ports_info() {
	_ports_check_exists
	local lib_name="$1"
	if ! _ports_validate_library "${lib_name}"; then
		log_error "Library '${lib_name}' not found."
		return 1
	fi

	log_info --draw-line "Information: ${lib_name}"

	# Fetch metadata through Python
	local metadata=$(python3 "${KOSAIO_DIR}/scripts/engine/py/main.py" port_info "${lib_name}" 2>/dev/null)

	# Parse variables from python output
	local PORTNAME=$(echo "$metadata" | grep "^PORTNAME=" | cut -d'=' -f2-)
	local SHORT_DESC=$(echo "$metadata" | grep "^SHORT_DESC=" | cut -d'=' -f2-)
	local DEPENDENCIES=$(echo "$metadata" | grep "^DEPENDENCIES=" | cut -d'=' -f2-)

	printf "Port Name:    %s\n" "${PORTNAME:-$lib_name}"
	printf "Description:  %s\n" "${SHORT_DESC:-No description}"
	printf "Dependencies: %s\n" "${DEPENDENCIES:-None}"

	local installed_version=$(ports_get_installed_version "${lib_name}")
	if [ $? -eq 0 ]; then
		log_success "Installed: ${installed_version}"
	else
		log_info "Not installed"
	fi
}

function ports_install() {
	_ports_check_exists
	_ports_check_requirements

	local python_engine="${KOSAIO_DIR}/scripts/engine/py/main.py"
	local force_reinstall=false
	local targets=()

	# Parse arguments for flags and targets
	for arg in "$@"; do
		if [ "$arg" == "--reinstall" ]; then
			force_reinstall=true
		else
			targets+=("$arg")
		fi
	done

	log_info "Resolving dependency tree..."
	local final_targets=()
	local dependencies=()

	if [ -f "$python_engine" ]; then
		# Bulk resolve all targets at once
		local resolved_string
		resolved_string=$(python3 "$python_engine" resolve_deps "${targets[@]}")
		read -r -a final_targets <<< "$resolved_string"
		
		# Identify which ones are dependencies (not in the original targets list)
		for t in "${final_targets[@]}"; do
			local is_direct=false
			for orig in "${targets[@]}"; do
				# Check direct match or case-insensitive match
				if [[ "${t,,}" == "${orig,,}" ]]; then
					is_direct=true
					break
				fi
			done
			if [ "$is_direct" = false ]; then
				dependencies+=("$t")
			fi
		done
	else
		final_targets=("${targets[@]}")
	fi

	# If there are dependencies, warn the user
	if [ ${#dependencies[@]} -gt 0 ]; then
		log_warn "The following dependencies will also be installed:"
		printf "  ${C_GRAY}→ %s${C_RESET}\n" "${dependencies[@]}"
		echo ""
		if ! confirm "Do you want to continue with the installation?" "Y"; then
			log_info "Installation cancelled."
			return 0
		fi
	fi

	for lib_name in "${final_targets[@]}"; do
		local resolved_name
		if resolved_name=$(ports_resolve_name "${lib_name}"); then
			lib_name="${resolved_name}"
		else
			log_error "Library '${lib_name}' not found."
			continue
		fi

		if ports_is_installed "${lib_name}"; then
			if [ "$force_reinstall" = true ]; then
				log_warn "Reinstalling ${lib_name} (forcing uninstall first)..."
				ports_uninstall "${lib_name}"
			else
				log_success "${lib_name} is already installed. Use --reinstall to force."
				continue
			fi
		fi

		log_info --draw-line "Installing ${lib_name}..."
		export KOS_BASE="${KOS_DIR}"
		export KOS_PORTS="${KOS_PORTS_DIR}"
		# Ensure KOS environment (compilers/path) is loaded
		if [ -f "${KOS_BASE}/environ.sh" ]; then
			source "${KOS_BASE}/environ.sh"
		fi
		export KOS_PORTS_BASE="${KOS_PORTS_DIR}"

		local make_targets="install"
		[ "${KOSAIO_CLEAN_AFTER:-false}" = true ] && make_targets="install clean"

		# Pre-install Snapshot
		local pre_snap="/tmp/ports_pre_${lib_name}.list"
		local post_snap="/tmp/ports_post_${lib_name}.list"

		# Store manifest in KOS_BASE root
		local manifest_dir="${KOS_BASE}/.kos-manifest"
		mkdir -p "${manifest_dir}"
		local manifest_file="${manifest_dir}/${lib_name}.manifest"

		_ports_snapshot "${pre_snap}"
		
		# Ensure source exists (implied fetch should have happened or be handled)
		# NOTE: KOS Ports Makefile usually handles fetch? No, usually we run 'make' in the dir.
		# If the dir doesn't exist, we can't run make.
		if ! check_dir_soft "${KOS_PORTS_DIR}/${lib_name}"; then
			log_warn "Source for ${lib_name} not found. Attempting to fetch..."
			# Optional: Try to clone/fetch if missing?
			# For now, just error out soft
			continue
		fi

		if (cd "${KOS_PORTS_DIR}/${lib_name}" && ${KOS_MAKE} ${make_targets}); then
			# Post-install Snapshot & Diff
			_ports_snapshot "${post_snap}"
			comm -13 "${pre_snap}" "${post_snap}" > "${manifest_file}"

			log_success "${lib_name} installed."
			success_libs+=("${lib_name}")

			# Cleanup snaps
			rm -f "${pre_snap}" "${post_snap}"
		else
			log_error "${lib_name} failed."
			rm -f "${pre_snap}" "${post_snap}"
			break
		fi
	done
	_ports_print_summary "Installation" "${success_libs[@]}"
}

function ports_uninstall() {
	_ports_check_exists
	local success_libs=()

	for lib_name in "$@"; do
		local resolved_name
		if resolved_name=$(ports_resolve_name "${lib_name}"); then
			lib_name="${resolved_name}"
		else
			log_error "Library '${lib_name}' not found."
			continue
		fi

		log_info --draw-line "Uninstalling ${lib_name}..."
		local lib_dir="${KOS_PORTS_DIR}/${lib_name}"
		local manifest_file="${KOS_BASE}/.kos-manifest/${lib_name}.manifest"
		local tracking_file="${KOS_PORTS_DIR}/lib/.kos-ports/${lib_name}"

		# 1. Try standard uninstall (Best Effort) + Deep Cleanup
		# Use 'distclean' to remove downloaded source tarballs/folders
		local make_targets="uninstall distclean"
		if [ -d "${lib_dir}" ]; then
			log_info "Running port cleanup..."
			(cd "${lib_dir}" && ${KOS_MAKE} ${make_targets} 2>/dev/null) || true
			
			# Fallback: Manual cleanup of KOS-PORTS specific artifacts
			# This ensures the [S] (Source) icon disappears from 'kosaio list'
			rm -rf "${lib_dir}/dist" "${lib_dir}/build" "${lib_dir}/inst" 2>/dev/null
		fi

		# 2. Manifest Cleanup (Surgical Removal of installed files)
		if [ -f "${manifest_file}" ]; then
			log_info "Removing installed files via manifest..."
			while IFS= read -r file; do
				if [ -f "$file" ]; then
					rm -f "$file"
				fi
			done < "${manifest_file}"
			rm -f "${manifest_file}"
		else
			log_warn "No manifest file found for ${lib_name}. Manual cleanup might be needed."
		fi

		# 3. Cleanup tracking and common include dirs
		rm -f "${tracking_file}"
		rm -rf "${KOS_PORTS_DIR}/include/${lib_name}" 2>/dev/null || true
		rm -rf "${KOS_BASE}/include/${lib_name}" 2>/dev/null || true

		log_success "${lib_name} uninstalled."
		success_libs+=("${lib_name}")
	done
	_ports_print_summary "Uninstallation" "${success_libs[@]}"
}
