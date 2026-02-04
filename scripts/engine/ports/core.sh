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

function _ports_parse_args() {
	local force_reinstall_ref="$1"
	local targets_ref="$2"
	shift 2

	for arg in "$@"; do
		if [ "$arg" == "--reinstall" ]; then
			eval "${force_reinstall_ref}=true"
		else
			eval "${targets_ref}+=(\"$arg\")"
		fi
	done
}

function _ports_resolve_dependencies() {
	local python_engine="$1"
	local targets_ref="$2"
	local final_targets_ref="$3"
	local dependencies_ref="$4"

	local -n targets_val="$targets_ref"
	local -n final_targets_val="$final_targets_ref"
	local -n dependencies_val="$dependencies_ref"

	if [ -f "$python_engine" ]; then
		local resolved_string
		resolved_string=$(python3 "$python_engine" resolve_deps "${targets_val[@]}")
		read -r -a final_targets_val <<< "$resolved_string"
		
		for t in "${final_targets_val[@]}"; do
			local is_direct=false
			for orig in "${targets_val[@]}"; do
				if [[ "${t,,}" == "${orig,,}" ]]; then
					is_direct=true
					break
				fi
			done
			[ "$is_direct" = false ] && dependencies_val+=("$t")
		done
	else
		final_targets_val=("${targets_val[@]}")
	fi

	if [ ${#dependencies_val[@]} -gt 0 ]; then
		log_warn "The following dependencies will also be installed:"
		printf "  ${C_GRAY}→ %s${C_RESET}\n" "${dependencies_val[@]}"
		echo ""
		if ! confirm "Do you want to continue with the installation?" "Y"; then
			log_info "Installation cancelled."
			return 1
		fi
	fi
	return 0
}

function _ports_check_update_status() {
	local lib_name="$1"
	local python_engine="$2"
	local force_reinstall_ref="$3"

	local metadata
	metadata=$(python3 "${python_engine}" port_info "${lib_name}" 2>/dev/null)
	
	local installed_ver
	installed_ver=$(ports_get_installed_version "${lib_name}") || installed_ver=""
	
	local current_ver=$(echo "$metadata" | grep "^PORTVERSION=" | cut -d'=' -f2-)
	local git_repo=$(echo "$metadata" | grep "^GIT_REPOSITORY=" | cut -d'=' -f2-)
	local git_branch=$(echo "$metadata" | grep "^GIT_BRANCH=" | cut -d'=' -f2-)

	if [ -n "$installed_ver" ]; then
		if [ "$installed_ver" != "$current_ver" ] && [ "$current_ver" != "unknown" ]; then
			log_info "Version update detected for ${lib_name}: ${C_YELLOW}${installed_ver}${C_RESET} -> ${C_GREEN}${current_ver}${C_RESET}"
			eval "${force_reinstall_ref}=true"
		elif [ -n "$git_repo" ] && [[ "${FUNCNAME[2]}" == "ports_update" ]]; then
			if [[ "$current_ver" =~ ^[0-9] ]] && [ "${!force_reinstall_ref}" = false ]; then
				local hash_file="${KOS_PORTS_DIR}/lib/.kos-ports/${lib_name}.hash"
				if [ -f "$hash_file" ]; then
					log_success "${lib_name} is already installed (${installed_ver}) and is a stable version. Skipping git check."
					return 10 # SKIP
				fi
			fi

			log_info "Checking remote Git hash for ${lib_name}..."
			local remote_hash local_hash
			local ref_match="HEAD"
			[ -n "$git_branch" ] && ref_match="refs/heads/${git_branch}"
			
			remote_hash=$(git ls-remote "$git_repo" "$ref_match" 2>/dev/null | awk '{print $1}')
			local hash_file="${KOS_PORTS_DIR}/lib/.kos-ports/${lib_name}.hash"
			[ -f "$hash_file" ] && local_hash=$(cat "$hash_file")

			if [ -n "$remote_hash" ] && [ "$remote_hash" != "$local_hash" ]; then
				[ -n "$local_hash" ] && log_info "New commits found on Git remote for ${lib_name} (branch: ${git_branch:-default})."
				eval "${force_reinstall_ref}=true"
			else
				log_success "${lib_name} is already installed and is latest version."
				return 10 # SKIP
			fi
		elif [ "${!force_reinstall_ref}" = true ]; then
			log_warn "Reinstalling ${lib_name} (forcing uninstall first)..."
			ports_uninstall "${lib_name}"
		else
			log_success "${lib_name} is already installed (${installed_ver}). Use --reinstall to force."
			return 10 # SKIP
		fi
	fi

	if [ "${!force_reinstall_ref}" = true ] && [ -n "$installed_ver" ]; then
		ports_uninstall "${lib_name}"
	fi

	# Export these for execute_install
	export LAST_GIT_REPO="$git_repo"
	export LAST_GIT_BRANCH="$git_branch"
	return 0
}

function _ports_execute_install() {
	local lib_name="$1"
	local git_repo="$2"
	local git_branch="$3"

	log_info --draw-line "Installing ${lib_name}..."
	
	export KOS_BASE="${KOS_DIR}"
	[ -f "${KOS_BASE}/environ.sh" ] && source "${KOS_BASE}/environ.sh"
	
	# PATH PROTECTION: Re-enforce KOSAIO's Choice
	export KOS_PORTS="${KOS_PORTS_DIR}"
	export KOS_PORTS_BASE="${KOS_PORTS_DIR}"

	local make_targets="install"
	[ "${KOSAIO_CLEAN_AFTER:-false}" = true ] && make_targets="install clean"

	local pre_snap="/tmp/ports_pre_${lib_name}.list"
	local post_snap="/tmp/ports_post_${lib_name}.list"
	local manifest_dir="${KOS_BASE}/.kos-manifest"
	mkdir -p "${manifest_dir}"
	local manifest_file="${manifest_dir}/${lib_name}.manifest"

	_ports_snapshot "${pre_snap}"
	
	if ! check_dir_soft "${KOS_PORTS_DIR}/${lib_name}"; then
		log_warn "Source for ${lib_name} not found. Skipping."
		return 1
	fi

	if (cd "${KOS_PORTS_DIR}/${lib_name}" && ${KOS_MAKE} ${make_targets}); then
		_ports_snapshot "${post_snap}"
		comm -13 "${pre_snap}" "${post_snap}" > "${manifest_file}"

		if [ -n "$git_repo" ]; then
			local ref_match="HEAD"
			[ -n "$git_branch" ] && ref_match="refs/heads/${git_branch}"
			local current_hash=$(git ls-remote "$git_repo" "$ref_match" 2>/dev/null | awk '{print $1}')
			[ -n "$current_hash" ] && echo "$current_hash" > "${KOS_PORTS_DIR}/lib/.kos-ports/${lib_name}.hash"
		fi

		log_success "${lib_name} installed."
		rm -f "${pre_snap}" "${post_snap}"
		return 0
	else
		log_error "${lib_name} failed."
		rm -f "${pre_snap}" "${post_snap}"
		return 1
	fi
}

function ports_install() {
	_ports_check_exists
	_ports_check_requirements

	local python_engine="${KOSAIO_DIR}/scripts/engine/py/main.py"
	local force_reinstall=false
	local targets=()
	local final_targets=()
	local dependencies=()
	local success_libs=()

	_ports_parse_args force_reinstall targets "$@"
	_ports_resolve_dependencies "$python_engine" targets final_targets dependencies || return 0

	for lib_name in "${final_targets[@]}"; do
		local resolved_name
		if resolved_name=$(ports_resolve_name "${lib_name}"); then
			lib_name="${resolved_name}"
		else
			log_error "Library '${lib_name}' not found."
			continue
		fi

		# Reset local force reinstall for each lib unless globally set
		local current_force="$force_reinstall"
		_ports_check_update_status "${lib_name}" "$python_engine" current_force || {
			[ $? -eq 10 ] && continue
			break
		}

		_ports_execute_install "${lib_name}" "$LAST_GIT_REPO" "$LAST_GIT_BRANCH" && success_libs+=("${lib_name}") || break
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
