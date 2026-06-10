#!/bin/bash
# scripts/registry/process-standard.sh
# Generic registry template for tools that follow standard build patterns.
# Reads all data from KOSAIO_TOOL_* config variables.
# Override individual kosaio_reg_* functions in a custom manifest for specialized tools.

ID="${KOSAIO_TOOL_ID}"
NAME="${KOSAIO_TOOL_NAME}"
DESC="${KOSAIO_TOOL_DESC}"
TAGS="${KOSAIO_TOOL_TAGS[*]}"
TYPE="${KOSAIO_TOOL_TYPE[*]}"
DEPS="${KOSAIO_TOOL_DEPS[*]}"
REPO="${KOSAIO_TOOL_REPO}"
BRANCH="${KOSAIO_TOOL_BRANCH}"

# If KOSAIO_TOOL_DIR_OVERRIDE is set, use it as tool_dir instead of kosaio_get_tool_dir
__get_tool_dir() {
	echo "${KOSAIO_TOOL_DIR_OVERRIDE:-$(kosaio_get_tool_dir "$ID")}"
}

function kosaio_reg_clone() {
	local tool_dir=$(__get_tool_dir)

	if [ -z "${KOSAIO_TOOL_REPO:-}" ]; then
		log_info "${NAME} has no repository — nothing to clone."
		return 0
	fi

	log_info --draw-line "Cloning ${NAME}..."

	local clone_args=()
	[[ "${KOSAIO_TOOL_CLONE_RECURSIVE:-false}" == "true" ]] && clone_args+=(--recursive)
	[[ -n "${KOSAIO_TOOL_BRANCH:-}" ]] && clone_args+=(--branch "${KOSAIO_TOOL_BRANCH}")

	kosaio_git_clone "${clone_args[@]}" "${KOSAIO_TOOL_REPO}" "${tool_dir}"
}

function kosaio_reg_apply_config() {
	# Tool apply-config hook (from helper) overrides default
	if declare -F kosaio_tool_apply_config &>/dev/null; then
		kosaio_tool_apply_config "$@"
		return $?
	fi

	local tool_dir=$(__get_tool_dir)
	[ -d "$tool_dir" ] || return 0

	local cfg_path="${KOSAIO_DIR}/data/cfg/${ID}.cfg"
	local cfg_default="${KOSAIO_DIR}/scripts/registry/cfg/${ID}.cfg.default"
	local cfg_file=""

	local build_args=()

	if [ -f "$cfg_path" ]; then
		cfg_file="$cfg_path"
	elif [ -f "$cfg_default" ]; then
		cfg_file="$cfg_default"
	fi

	if [ -n "$cfg_file" ]; then
		source "$cfg_file"
		build_args=("${KOSAIO_TOOL_ARGS[@]}")
	fi

	# Pre-build translation (e.g. sdl2 user-friendly args)
	if [ -n "${KOSAIO_TOOL_PREBUILD_FUNC:-}" ]; then
		$KOSAIO_TOOL_PREBUILD_FUNC "${build_args[@]}" || return 1
		[ ${#KOSAIO_TRANSLATED_ARGS[@]} -gt 0 ] && build_args=("${KOSAIO_TRANSLATED_ARGS[@]}")
	fi

	case "${KOSAIO_TOOL_BUILD_SYSTEM}" in
		configure)
			cd "$tool_dir"
			[ -f Makefile ] && return 0
			./configure --prefix="${KOSAIO_TOOL_INSTALLATION_FOLDER:-/usr/local}" "${build_args[@]}"
			;;
		cmake)
			cd "$tool_dir"
			cmake -S . -B "${KOSAIO_TOOL_BUILD_DIR:-build}" "${build_args[@]}"
			;;
		meson)
			cd "$tool_dir"
			meson setup "${KOSAIO_TOOL_BUILD_DIR:-builddir}" "${build_args[@]}"
			;;
		make)
			:
			;;
	esac
}

function kosaio_reg_build() {
	local tool_dir=$(__get_tool_dir)

	# Tool build hook (from helper) overrides standard build
	if declare -F kosaio_tool_build &>/dev/null; then
		kosaio_tool_build "$@"
		return $?
	fi

	[ -d "$tool_dir" ] || { log_error "${NAME} source missing. Run 'kosaio clone ${ID}' first."; return 1; }

	# Apply config before building (reads .cfg if present)
	kosaio_reg_apply_config "$@"

	# Build warning from config (for tools without build hooks)
	if [ ${#KOSAIO_TOOL_BUILD_WARNING[@]} -gt 0 ]; then
		log_box --type=warn "${KOSAIO_TOOL_BUILD_WARNING[0]}" "${KOSAIO_TOOL_BUILD_WARNING[@]:1}"
		if [ "${KOSAIO_TOOL_INSTALL_CONFIRM:-false}" = true ]; then
			confirm "Proceed with build?" || return 1
		fi
	fi

	case "${KOSAIO_TOOL_BUILD_SYSTEM}" in
		cmake)
			local toolchain=""

			if [ -n "${KOSAIO_TOOL_TOOLCHAIN:-}" ]; then
				toolchain="$KOSAIO_TOOL_TOOLCHAIN"
			elif [ -n "${KOS_BASE:-}" ] && [ -f "${KOS_BASE}/utils/cmake/dreamcast.toolchain.cmake" ]; then
				toolchain="${KOS_BASE}/utils/cmake/dreamcast.toolchain.cmake"
			fi

			cd "${tool_dir}/${KOSAIO_TOOL_BUILD_DIR:-build}"
			make -j$(nproc)
			;;
		make)
			cd "${tool_dir}/${KOSAIO_TOOL_BUILD_SUBDIR:-.}"
			make -j$(nproc) ${KOSAIO_TOOL_BUILD_TARGET:-} "$@"
			;;
		configure)
			cd "${tool_dir}/${KOSAIO_TOOL_BUILD_SUBDIR:-.}"
			make -j$(nproc)
			;;
		meson)
			kosaio_meson_build "$@"
			;;
		none)
			log_info "No compilation needed for ${NAME}."
			;;
	esac
}

function kosaio_reg_apply() {
	local tool_dir=$(__get_tool_dir)

	# Tool apply hook (from helper) overrides standard install
	if declare -F kosaio_tool_apply &>/dev/null; then
		kosaio_tool_apply "$@"
		return $?
	fi

	case "${KOSAIO_TOOL_INSTALL_METHOD}" in
		make_install)
			cd "${tool_dir}/${KOSAIO_TOOL_BUILD_SUBDIR:-.}"
			make -j$(nproc) "${KOSAIO_TOOL_MAKE_ARGS[@]}" install
			;;
		cmake_install)
			cmake --install "${tool_dir}/${KOSAIO_TOOL_BUILD_DIR:-build}"
			;;
		meson_install)
			meson install -C "${tool_dir}/${KOSAIO_TOOL_BUILD_DIR:-builddir}"
			;;
		cp)
			local src="${tool_dir}/${KOSAIO_TOOL_BINARY_SUBDIR:-.}"
			local dst="${KOSAIO_TOOL_INSTALLATION_FOLDER}"
			
			if [ -z "$dst" ]; then
				log_error "KOSAIO_TOOL_INSTALLATION_FOLDER is not set."
				return 1
			fi

			mkdir -p "$dst"

			for bin in "${KOSAIO_TOOL_BINARIES[@]}"; do
				cp -v "${src}/${bin}" "${dst}/" || return 1
			done
			;;
		none)
			log_success "${NAME} has no additional install step."
			;;
	esac

	# Post-install symlinks
	if [ -n "${KOSAIO_TOOL_SYMLINKS+set}" ] && [ ${#KOSAIO_TOOL_SYMLINKS[@]} -gt 0 ]; then
		for entry in "${KOSAIO_TOOL_SYMLINKS[@]}"; do
			local target="${entry%%:*}"
			local link="${entry#*:}"
			mkdir -p "$(dirname "$link")"
			ln -sf "$target" "$link"
			log_info "Symlink: $link -> $target"
		done
	fi

	touch "$tool_dir/.kosaio_installed"
}

function kosaio_reg_check_health() {
	# Tool health check hook (from helper) overrides standard check
	if declare -F kosaio_tool_check_health &>/dev/null; then
		kosaio_tool_check_health "$@"
		return $?
	fi

	local found=0
	local missing=0
	local items=()

	for lib in "${KOSAIO_TOOL_LIBS[@]}"; do
		if [ -f "$lib" ]; then
			found=1
			items+=("${C_GREEN}✓${C_RESET} $lib")
		else
			items+=("${C_RED}✗${C_RESET} $lib")
			missing=1
		fi
	done

	if [ "$missing" -eq 0 ]; then
		for dir in "${KOSAIO_TOOL_INCLUDE_DIRS[@]}"; do
			if [ -d "$dir" ]; then
				items+=("${C_GREEN}✓${C_RESET} $dir")
			else
				items+=("${C_RED}✗${C_RESET} $dir")
				missing=1
			fi
		done
	fi

	if [ "$found" -eq 0 ]; then
		log_box --info "${NAME} — Health Check" \
			"${C_YELLOW}Status:${C_RESET} ${C_RED}Not Installed${C_RESET}" \
			"" \
			"${items[@]}"
		return 1
	fi

	if [ "$missing" -eq 0 ]; then
		# Reconcile: marker exists only if all libs are present
		if [ -n "${KOSAIO_TOOL_LIBS[0]:-}" ]; then
			touch "$tool_dir/.kosaio_installed"
		fi
		log_box --info "${NAME} — Health Check" \
			"${C_YELLOW}Status:${C_RESET} ${C_GREEN}Healthy${C_RESET}" \
			"" \
			"${items[@]}"
		return 0
	fi

	# Reconcile: remove marker if anything is missing
	rm -f "$tool_dir/.kosaio_installed"

	log_box --type=warn "${NAME} — Health Check" \
		"${C_YELLOW}Status:${C_RESET} ${C_RED}Incomplete${C_RESET}" \
		"" \
		"${items[@]}"
	return 2
}

function kosaio_reg_uninstall() {
	# Tool uninstall hook (from helper) overrides standard uninstall
	if declare -F kosaio_tool_uninstall &>/dev/null; then
		kosaio_tool_uninstall "$@"
		return $?
	fi

	local tool_dir=$(__get_tool_dir)
	log_info "Removing ${NAME} files..."

	if [ "${KOSAIO_TOOL_CAN_MAKE_UNINSTALL:-false}" = true ] && [ -f "$tool_dir/Makefile" ]; then
		(cd "$tool_dir" && make "${KOSAIO_TOOL_MAKE_ARGS[@]}" uninstall || true)
	fi

	for dir in "${KOSAIO_TOOL_INCLUDE_DIRS[@]}"; do
		rm -rf "$dir"
	done

	for lib in "${KOSAIO_TOOL_LIBS[@]}"; do
		rm -f "$lib"
	done

	rm -rf "$tool_dir"
	rm -f "$tool_dir/.kosaio_installed"
	log_success "${NAME} removed."
}

function kosaio_reg_info() {
	# Tool info hook (from helper) overrides standard info
	if declare -F kosaio_tool_info &>/dev/null; then
		kosaio_tool_info "$@"
		return $?
	fi

	# Auto-detect status from LIBS
	local status="${C_RED}Not Compiled${C_RESET}"
	for lib in "${KOSAIO_TOOL_LIBS[@]}"; do
		[ -f "$lib" ] && { status="${C_GREEN}Compiled${C_RESET}"; break; }
	done

	log_box --info "${NAME}" \
		"${C_YELLOW}Description:${C_RESET} ${DESC}" \
		"${C_YELLOW}Type:${C_RESET}   ${KOSAIO_TOOL_TYPE[*]}" \
		"${C_YELLOW}Status:${C_RESET} ${status}" \
		"${C_YELLOW}Path:${C_RESET}   $(__get_tool_dir)"

	for line in "${KOSAIO_TOOL_INFO_EXTRA[@]}"; do
		echo "$line"
	done
}

function kosaio_reg_update() {
	# Tool update hook (from helper) overrides standard update
	if declare -F kosaio_tool_update &>/dev/null; then
		kosaio_tool_update "$@"
		return $?
	fi

	local tool_dir=$(__get_tool_dir)
	kosaio_standard_update_flow "${ID}" "${NAME}" "$tool_dir" "$@"
}

function kosaio_reg_clean() {
	local tool_dir=$(__get_tool_dir)
	[ -d "$tool_dir" ] || return 0

	if [ "${KOSAIO_TOOL_CAN_MAKE_CLEAN:-false}" = true ] && [ -f "$tool_dir/Makefile" ]; then
		(cd "$tool_dir" && make clean) || true
	else
		local build_dir="${KOSAIO_TOOL_BUILD_DIR:-build}"
		[ -d "${tool_dir}/${build_dir}" ] && rm -rf "${tool_dir}/${build_dir}"
	fi
	rm -f "$(dirname "$tool_dir")/.kosaio_installed"
	log_success "${NAME} cleaned."
}

function kosaio_reg_export() {
	# Tool export hook (from helper) overrides standard export
	if declare -F kosaio_tool_export &>/dev/null; then
		kosaio_tool_export "$@"
		return $?
	fi

	local tool_dir=$(__get_tool_dir)
	local src="${tool_dir}/${KOSAIO_TOOL_BINARY_SUBDIR:-.}"
	local host_out="${KOSAIO_DIR}/data/exports/${ID}"

	if [ ${#KOSAIO_TOOL_BINARIES[@]} -eq 0 ]; then
		log_info "Nothing to export for ${NAME}."
		return 0
	fi

	mkdir -p "$host_out"
	for bin in "${KOSAIO_TOOL_BINARIES[@]}"; do
		if [ ! -f "${src}/${bin}" ]; then
			log_error "Binary '${bin}' not found at ${src}/. Build first."
			return 1
		fi
		cp -v "${src}/${bin}" "${host_out}/"
	done
	log_success "${NAME} exported to ${host_out}."
}

function kosaio_reg_install() {
	# Tool install hook (from helper) overrides standard install pipeline
	if declare -F kosaio_tool_install &>/dev/null; then
		kosaio_tool_install "$@"
		return $?
	fi

	# Interactive confirmation before install
	if [ "${KOSAIO_TOOL_INSTALL_CONFIRM:-false}" = true ]; then
		if [ ${#KOSAIO_TOOL_INSTALL_WARNING[@]} -gt 0 ]; then
			log_box --type=warn "${KOSAIO_TOOL_INSTALL_WARNING[0]}" "${KOSAIO_TOOL_INSTALL_WARNING[@]:1}"
		fi
		confirm "Proceed with installation?" || return 1
	fi

	kosaio_reg_clone
	kosaio_reg_build
	kosaio_reg_apply

	if [ -n "${KOSAIO_TOOL_POSTINSTALL_MESSAGE:-}" ]; then
		log_info "$KOSAIO_TOOL_POSTINSTALL_MESSAGE"
	fi
	touch "$tool_dir/.kosaio_installed"
	log_success "${NAME} installation complete."
}
