#!/bin/bash
# scripts/engine/ports/lifecycle.sh

function ports_clone() {
	_ports_check_exists
	_ports_check_requirements

	local success_libs=()
	local targets=()

	if [ "$#" -eq 0 ] || [ "$1" = "all" ]; then
		for lib_dir in $(find "${KOS_PORTS_DIR}" -maxdepth 1 -type d); do
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
		if ! _ports_validate_library "${lib_name}"; then
			log_error "Library '${lib_name}' not found. Skipping."
			continue
		fi

		log_info --draw-line "Fetching source for ${lib_name}..."
		if (cd "${KOS_PORTS_DIR}/${lib_name}" && ${KOS_MAKE} fetch); then
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
	local lib_name="$1"; local ref="$2"

	if ! _ports_validate_library "${lib_name}"; then
		log_error "Library '${lib_name}' not found."
		return 1
	fi

	local lib_dir="${KOS_PORTS_DIR}/${lib_name}"
	check_dir_soft "${lib_dir}" "Port source not found for ${lib_name}" || return 1
	local git_dist_dir=$(find "${lib_dir}/dist" -maxdepth 2 -name ".git" -type d -print -quit 2>/dev/null | xargs dirname 2>/dev/null)

	if [ -z "${git_dist_dir}" ]; then
		log_error "No git repository found for ${lib_name} in dist/. Run 'kosaio clone ${lib_name}' first."
		return 1
	fi

	log_info --draw-line "Changing git reference for ${lib_name} to ${ref}..."
	if kosaio_git_checkout "${git_dist_dir}" "${ref}"; then
		log_success "${lib_name} is now at ${ref}"
	else
		log_error "Failed to checkout ${ref}"
	fi
}

function ports_reset() {
	_ports_check_exists
	local lib_name="$1"
	if ! _ports_validate_library "${lib_name}"; then
		log_error "Library '${lib_name}' not found."
		return 1
	fi

	check_dir_soft "${KOS_PORTS_DIR}/${lib_name}" "Port source not found" || return 1
	log_info --draw-line "Resetting ${lib_name} to official version..."
	if (cd "${KOS_PORTS_DIR}/${lib_name}" && ${KOS_MAKE} fetch); then
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
			(cd "${KOS_PORTS_DIR}/${lib_name}" && ${KOS_MAKE} clean)
			log_success "${lib_name} cleaned."
		fi
	done
}

function ports_update() {
	_ports_check_exists
	_ports_check_requirements

	log_info --draw-line "Updating kos-ports repository..."
	kosaio_git_common_update "${KOS_PORTS_DIR}"
	(cd "${KOS_PORTS_DIR}" && git submodule update --init --recursive)

	ports_install "$@"
}

function ports_build() {
	_ports_check_exists
	_ports_check_requirements
	local success_libs=()

	for lib_name in "$@"; do
		if ! _ports_validate_library "${lib_name}"; then
			log_error "Library '${lib_name}' not found."
			continue
		fi

		check_dir_soft "${KOS_PORTS_DIR}/${lib_name}" "Port source not found" || continue
		log_info --draw-line "Building ${lib_name}..."
		local make_targets="build-stamp"
		[ "${KOSAIO_CLEAN_AFTER:-false}" = true ] && make_targets="build-stamp clean"

		if (cd "${KOS_PORTS_DIR}/${lib_name}" && ${KOS_MAKE} ${make_targets}); then
			log_success "${lib_name} built."
			success_libs+=("${lib_name}")
		else
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
		if ! _ports_validate_library "${lib_name}"; then
			log_error "Library '${lib_name}' not found."
			continue
		fi

		check_dir_soft "${KOS_PORTS_DIR}/${lib_name}" "Port source not found" || continue
		log_info --draw-line "Applying ${lib_name}..."
		if (cd "${KOS_PORTS_DIR}/${lib_name}" && ${KOS_MAKE} install); then
			log_success "${lib_name} applied."
			success_libs+=("${lib_name}")
		else
			log_error "${lib_name} application failed."
			break
		fi
	done
	_ports_print_summary "Application" "${success_libs[@]}"
}
