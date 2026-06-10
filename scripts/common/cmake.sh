#!/bin/bash
# scripts/common/cmake.sh
# Helper for cmake-based tools (configure only — make called separately)

kosaio_cmake_configure() {
	local toolchain=""
	local source_dir=".."
	# shellcheck disable=SC2154
	local build_dir="${tool_dir}/build"

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--toolchain) toolchain="$2"; shift 2 ;;
			--source) source_dir="$2"; shift 2 ;;
			--build-dir) build_dir="$2"; shift 2 ;;
			--) shift; break ;;
			*) break ;;
		esac
	done

	mkdir -p "$build_dir"
	pushd "$build_dir" > /dev/null || return 1

	local cmake_cmd=(cmake -G "Unix Makefiles")

	[[ -n "$toolchain" ]] && cmake_cmd+=(-DCMAKE_TOOLCHAIN_FILE="$toolchain")
	[[ ${#KOSAIO_TOOL_ARGS[@]} -gt 0 ]] && cmake_cmd+=("${KOSAIO_TOOL_ARGS[@]}")
	[[ -n "${KOSAIO_TOOL_INSTALLATION_FOLDER}" ]] && cmake_cmd+=(-DCMAKE_INSTALL_PREFIX="${KOSAIO_TOOL_INSTALLATION_FOLDER}")
	[[ -n "${KOSAIO_TOOL_INSTALLATION_LIBDIR}" ]] && cmake_cmd+=(-DCMAKE_INSTALL_LIBDIR="${KOSAIO_TOOL_INSTALLATION_LIBDIR}")
	[[ -n "${KOSAIO_TOOL_INSTALLATION_INCLUDEDIR}" ]] && cmake_cmd+=(-DCMAKE_INSTALL_INCLUDEDIR="${KOSAIO_TOOL_INSTALLATION_INCLUDEDIR}")

	cmake_cmd+=("$@")
	cmake_cmd+=("$source_dir")

	log_info "Configuring with CMake..."
	"${cmake_cmd[@]}" || return 1

	popd > /dev/null || return 1
}
