#!/bin/bash
# scripts/registry/process-standard.sh
# Generic registry template for tools that follow standard build patterns.
# Reads all data from KOSAIO_TOOL_* config variables.
# Override individual reg_* functions in a custom manifest for specialized tools.

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

function reg_clone() {
	local tool_dir=$(__get_tool_dir)

	if [ -z "${KOSAIO_TOOL_REPO:-}" ]; then
		log_error "${NAME} has no repository configured. Cannot clone."
		return 1
	fi

	log_info --draw-line "Cloning ${NAME}..."

	local clone_args=()
	[[ "${KOSAIO_TOOL_CLONE_RECURSIVE:-false}" == "true" ]] && clone_args+=(--recursive)
	[[ -n "${KOSAIO_TOOL_BRANCH:-}" ]] && clone_args+=(--branch "${KOSAIO_TOOL_BRANCH}")

	kosaio_git_clone "${clone_args[@]}" "${KOSAIO_TOOL_REPO}" "${tool_dir}"
}

function reg_build() {
	local tool_dir=$(__get_tool_dir)
	[ -d "$tool_dir" ] || { log_error "${NAME} source missing. Run 'kosaio clone ${ID}' first."; return 1; }

	# Tool build hook (from helper) overrides standard build
	if declare -F kosaio_tool_build &>/dev/null; then
		kosaio_tool_build "$@"
		return $?
	fi

	# Build warning from config (for tools without build hooks)
	if [ ${#KOSAIO_TOOL_BUILD_WARNING[@]} -gt 0 ]; then
		log_box --type=warn "${KOSAIO_TOOL_BUILD_WARNING[0]}" "${KOSAIO_TOOL_BUILD_WARNING[@]:1}"
		if [ "${KOSAIO_TOOL_INSTALL_CONFIRM:-false}" = true ]; then
			confirm "Proceed with build?" || return 1
		fi
	fi

	# Pre-build hook for dynamic arg translation (e.g. sdl2)
	if [ -n "${KOSAIO_TOOL_PREBUILD_FUNC:-}" ]; then
		$KOSAIO_TOOL_PREBUILD_FUNC "$@" || return 1
		[ ${#KOSAIO_TRANSLATED_ARGS[@]} -gt 0 ] && set -- "${KOSAIO_TRANSLATED_ARGS[@]}"
	fi

	case "${KOSAIO_TOOL_BUILD_SYSTEM}" in
		cmake)
			local toolchain=""

			if [ -n "${KOSAIO_TOOL_TOOLCHAIN:-}" ]; then
				toolchain="$KOSAIO_TOOL_TOOLCHAIN"
			elif [ -n "${KOS_BASE:-}" ] && [ -f "${KOS_BASE}/utils/cmake/dreamcast.toolchain.cmake" ]; then
				toolchain="${KOS_BASE}/utils/cmake/dreamcast.toolchain.cmake"
			fi

			cd "${tool_dir}"
			kosaio_cmake_configure \
				--toolchain "$toolchain" \
				--build-dir "${KOSAIO_TOOL_BUILD_DIR:-build}" \
				"$@"

			cd "${tool_dir}/${KOSAIO_TOOL_BUILD_DIR:-build}"
			make -j$(nproc)
			;;
		make)
			cd "${tool_dir}/${KOSAIO_TOOL_BUILD_SUBDIR:-.}"
			make -j$(nproc) ${KOSAIO_TOOL_BUILD_TARGET:-} "$@"
			;;
		configure)
			cd "${tool_dir}/${KOSAIO_TOOL_BUILD_SUBDIR:-.}"
			./configure --prefix="${KOSAIO_TOOL_INSTALLATION_FOLDER:-/usr/local}" "$@"
			make -j$(nproc)
			;;
		meson)
			cd "${tool_dir}"
			local meson_build_dir="${KOSAIO_TOOL_BUILD_DIR:-builddir}"
			if [ "${KOSAIO_TOOL_MESON_CLEAN_BUILD:-false}" = true ]; then
				rm -rf "${tool_dir}/${meson_build_dir}"
			fi
			kosaio_meson_configure --build-dir "$meson_build_dir"
			kosaio_meson_build --build-dir "$meson_build_dir" "$@"
			;;
		none)
			log_info "No compilation needed for ${NAME}."
			;;
	esac
}

function reg_apply() {
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
	if [ ${#KOSAIO_TOOL_SYMLINKS[@]} -gt 0 ]; then
		for entry in "${KOSAIO_TOOL_SYMLINKS[@]}"; do
			local target="${entry%%:*}"
			local link="${entry#*:}"
			mkdir -p "$(dirname "$link")"
			ln -sf "$target" "$link"
			log_info "Symlink: $link -> $target"
		done
	fi
}

function reg_check_health() {
	local all_ok=0

	for lib in "${KOSAIO_TOOL_LIBS[@]}"; do
		[ -f "$lib" ] || { log_error "Missing: $lib"; all_ok=1; }
	done

	if [ "$all_ok" -eq 0 ]; then
		for dir in "${KOSAIO_TOOL_INCLUDE_DIRS[@]}"; do
			[ -d "$dir" ] || { log_error "Missing: $dir"; all_ok=1; }
		done
	fi

	[ "$all_ok" -eq 0 ] || return 2
	return 0
}

function reg_uninstall() {
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
	log_success "${NAME} removed."
}

function reg_info() {
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
		"${C_YELLOW}Type:${C_RESET}   ${KOSAIO_TOOL_TYPE[*]}" \
		"${C_YELLOW}Status:${C_RESET} ${status}" \
		"${C_YELLOW}Path:${C_RESET}   $(__get_tool_dir)"

	for line in "${KOSAIO_TOOL_INFO_EXTRA[@]}"; do
		echo "$line"
	done
}

function reg_update() {
	# Tool update hook (from helper) overrides standard update
	if declare -F kosaio_tool_update &>/dev/null; then
		kosaio_tool_update "$@"
		return $?
	fi

	local tool_dir=$(__get_tool_dir)
	kosaio_standard_update_flow "${ID}" "${NAME}" "$tool_dir" "$@"
}

function reg_clean() {
	local tool_dir=$(__get_tool_dir)
	[ -d "$tool_dir" ] || return 0

	if [ "${KOSAIO_TOOL_CAN_MAKE_CLEAN:-false}" = true ] && [ -f "$tool_dir/Makefile" ]; then
		(cd "$tool_dir" && make clean) || true
	else
		local build_dir="${KOSAIO_TOOL_BUILD_DIR:-build}"
		[ -d "${tool_dir}/${build_dir}" ] && rm -rf "${tool_dir}/${build_dir}"
	fi
	log_success "${NAME} cleaned."
}

function reg_export() {
	# Tool export hook (from helper) overrides standard export
	if declare -F kosaio_tool_export &>/dev/null; then
		kosaio_tool_export "$@"
		return $?
	fi

	local tool_dir=$(__get_tool_dir)
	local src="${tool_dir}/${KOSAIO_TOOL_BINARY_SUBDIR:-.}"
	local host_out="${KOSAIO_DIR}/out/${ID}"

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

function reg_install() {
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

	reg_clone
	reg_build
	reg_apply

	if [ -n "${KOSAIO_TOOL_POSTINSTALL_MESSAGE:-}" ]; then
		log_info "$KOSAIO_TOOL_POSTINSTALL_MESSAGE"
	fi
	log_success "${NAME} installation complete."
}
