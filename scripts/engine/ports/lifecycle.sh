#!/bin/bash
# scripts/engine/ports/lifecycle.sh

function ports_clone() {
	_ports_check_exists
	_ports_check_requirements "true"

	local success_libs=()
	local targets=()

	if [ "$#" -eq 0 ] || [ "$1" = "all" ]; then
		for lib_dir in $(find "${KOS_PORTS}" -maxdepth 1 -type d); do
			if [ -f "${lib_dir}/Makefile" ]; then
				local lib_name=$(basename "${lib_dir}")
				# Skip special directories
				[[ "${lib_name}" =~ ^(utils|scripts|include|lib|examples|kos-ports)$ ]] && continue
				targets+=("${lib_name}")
			fi
		done
	else
		targets=("$@")
	fi

	for lib_name in "${targets[@]}"; do
		local resolved_name
		if resolved_name=$(ports_resolve_name "${lib_name}"); then
			lib_name="${resolved_name}"
		else
			log_error "Library '${lib_name}' not found. Skipping."
			continue
		fi

		log_info --draw-line "Fetching source for ${lib_name}..."
		if (cd "${KOS_PORTS}/${lib_name}" && ${KOS_MAKE} fetch); then
			log_success "Source for ${lib_name} downloaded."
			success_libs+=("${lib_name}")
		else
			log_error "Failed to fetch source for ${lib_name}."
		fi
	done
	_ports_print_summary "Clone (Fetch)" "${success_libs[@]}"
}

function ports_checkout() {
	_ports_check_exists
	local lib_name="${1:-}"; local ref="${2:-}"

	if [ -z "${lib_name}" ] || [ -z "${ref}" ]; then
		log_error "Usage: kosaio checkout <port> <ref>"
		return 1
	fi

	# Resolve community aliases (e.g. aldc -> libAL) before touching the
	# filesystem: the directory under $KOS_PORTS uses the canonical name.
	local resolved_name
	if ! resolved_name=$(ports_resolve_name "${lib_name}"); then
		log_error "Library '${lib_name}' not found."
		return 1
	fi
	lib_name="${resolved_name}"

	local lib_dir="${KOS_PORTS}/${lib_name}"
	check_dir_soft "${lib_dir}" "Port source not found for ${lib_name}" || return 1
	local git_dist_dir=$(find "${lib_dir}/dist" -maxdepth 2 -name ".git" -type d -print -quit 2>/dev/null | xargs dirname 2>/dev/null)

	if [ -z "${git_dist_dir}" ]; then
		log_error "No git repository found for ${lib_name} in dist/. Run 'kosaio clone ${lib_name}' first."
		return 1
	fi

	log_info --draw-line "Changing git reference for ${lib_name} to ${ref}..."
	if kosaio_git_checkout "${git_dist_dir}" "${ref}"; then
		log_success "${lib_name} is now at ${ref}"
		log_info "Rebuild with: kosaio install ${lib_name} (or build/apply)"
	else
		log_error "Failed to checkout ${ref}"
		return 1
	fi
}

function ports_reset() {
	_ports_check_exists
	local lib_name="$1"
	if ! _ports_validate_library "${lib_name}"; then
		log_error "Library '${lib_name}' not found."
		return 1
	fi

	check_dir_soft "${KOS_PORTS}/${lib_name}" "Port source not found" || return 1
	log_info --draw-line "Resetting ${lib_name} to official version..."
	if (cd "${KOS_PORTS}/${lib_name}" && ${KOS_MAKE} fetch); then
		log_success "${lib_name} reset successful."
	else
		log_error "Failed to reset ${lib_name}."
	fi
}

function ports_clean() {
	_ports_check_exists
	for lib_name in "$@"; do
		if _ports_validate_library "${lib_name}"; then
			log_info --draw-line "Cleaning ${lib_name}..."
			(cd "${KOS_PORTS}/${lib_name}" && ${KOS_MAKE} clean)
			log_success "${lib_name} cleaned."
		fi
	done
}

function ports_update() {
	_ports_check_exists
	_ports_check_requirements "true"

	log_info --draw-line "Updating kos-ports repository..."
	
	# If there are arguments, we handle them individually
	if [ "$#" -gt 0 ]; then
		local port_name="$1"
		# Always update the recipe repository first
		local git_status=0
		kosaio_git_common_update "${KOS_PORTS}" --log-id "${port_name}" || git_status=$?
		
		# Now run install for each target. 
		# Our new smart ports_install will detect version changes.
		ports_install "$@"
		local install_status=$?

		# Map to KOSAIO status codes
		if [ $git_status -eq 1 ]; then
			return 11  # UPDATED
		elif [ $install_status -eq 0 ]; then
			return 10  # UP-TO-DATE
		fi
		return 1
	else
		# Just pull changes for the main repo
		local status=0
		kosaio_git_common_update "${KOS_PORTS}" || status=$?
		if [ $status -eq 1 ]; then
			(cd "${KOS_PORTS}" && git submodule update --init --recursive)
			log_success "kos-ports updated successfully."
			return 11
		elif [ $status -eq 0 ]; then
			log_info "kos-ports is already up-to-date."
			return 10
		fi
	fi
	return 1
}

function ports_build() {
	_ports_check_exists
	_ports_check_requirements
	local success_libs=()

	for lib_name in "$@"; do
		local resolved_name
		if resolved_name=$(ports_resolve_name "${lib_name}"); then
			lib_name="${resolved_name}"
		else
			log_error "Library '${lib_name}' not found."
			continue
		fi

		check_dir_soft "${KOS_PORTS}/${lib_name}" "Port source not found" || continue
		log_info --draw-line "Building ${lib_name}..."
		local make_targets="build-stamp"
		[ "${KOSAIO_CLEAN_AFTER:-false}" = true ] && make_targets="build-stamp clean"

		local broken_marker="${HOME}/.kosaio/states/${lib_name}_broken"
		mkdir -p "$(dirname "${broken_marker}")"
		if (cd "${KOS_PORTS}/${lib_name}" && ${KOS_MAKE} ${make_targets}); then
			rm -f "${broken_marker}"
			log_success "${lib_name} built."
			success_libs+=("${lib_name}")
		else
			touch "${broken_marker}"
			log_error "${lib_name} build failed."
			break
		fi
	done
	_ports_print_summary "Build" "${success_libs[@]}"
}

function ports_apply() {
	_ports_check_exists
	_ports_check_requirements
	local success_libs=()

	for lib_name in "$@"; do
		local resolved_name
		if resolved_name=$(ports_resolve_name "${lib_name}"); then
			lib_name="${resolved_name}"
		else
			log_error "Library '${lib_name}' not found."
			continue
		fi

		check_dir_soft "${KOS_PORTS}/${lib_name}" "Port source not found" || continue
		log_info --draw-line "Applying ${lib_name}..."
		local broken_marker="${HOME}/.kosaio/states/${lib_name}_broken"
		mkdir -p "$(dirname "${broken_marker}")"
		if (cd "${KOS_PORTS}/${lib_name}" && ${KOS_MAKE} install); then
			rm -f "${broken_marker}"
			log_success "${lib_name} applied."
			success_libs+=("${lib_name}")
		else
			touch "${broken_marker}"
			log_error "${lib_name} application failed."
			break
		fi
	done
	_ports_print_summary "Application" "${success_libs[@]}"
}

# Apply the registry patches for a port (scripts/registry/patches/<group>/) to
# every source tree under dist/ and build/ (the source of truth and the tree
# that actually compiles). Idempotent: already-applied patches are skipped.
function ports_patch() {
	_ports_check_exists
	_ports_check_requirements
	local lib_name="${1:-}"

	if [ -z "$lib_name" ]; then
		log_error "Usage: kosaio patch <library>"
		return 1
	fi

	local resolved_name
	if ! resolved_name=$(ports_resolve_name "${lib_name}"); then
		log_error "Library '${lib_name}' not found."
		return 1
	fi

	local lib_dir="${KOS_PORTS}/${resolved_name}"
	check_dir_soft "${lib_dir}" "Port source not found for ${resolved_name}" || return 1

	# Patch group: prefer the input name (community alias, e.g. aldc),
	# then fall back to the canonical resolved name.
	local group="${lib_name}"
	if [ ! -d "${KOSAIO_DIR}/scripts/registry/patches/${group}" ]; then
		group="${resolved_name}"
	fi
	if [ ! -d "${KOSAIO_DIR}/scripts/registry/patches/${group}" ]; then
		log_info "No patches found for '${lib_name}' — nothing to apply."
		return 0
	fi

	local trees=0
	local src_dir
	while IFS= read -r src_dir; do
		[ -z "$src_dir" ] && continue
		kosaio_apply_patches "$src_dir" "$group" || return 1
		trees=$((trees + 1))
	done < <(find "${lib_dir}/dist" "${lib_dir}/build" -mindepth 1 -maxdepth 2 -type d -name src -printf "%h\n" 2>/dev/null | sort -u)

	if [ "$trees" -eq 0 ]; then
		log_warn "No source tree found under ${lib_dir}/dist or ${lib_dir}/build. Run 'kosaio clone ${lib_name}' first."
	fi

	return 0
}
