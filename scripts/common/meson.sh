#!/bin/bash
# scripts/common/meson.sh
# Helper for meson-based tools (configure + build separated)

kosaio_meson_configure() {
	# shellcheck disable=SC2154
	local build_dir="${tool_dir}/builddir"

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--build-dir) build_dir="$2"; shift 2 ;;
			--) shift; break ;;
			*) break ;;
		esac
	done

	cd "${tool_dir}" || return 1

	local meson_cmd=(meson setup "$build_dir")

	[[ ${#KOSAIO_TOOL_ARGS[@]} -gt 0 ]] && meson_cmd+=("${KOSAIO_TOOL_ARGS[@]}")

	meson_cmd+=("$@")

	log_info "Configuring with Meson..."
	"${meson_cmd[@]}" || return 1
}

kosaio_meson_build() {
	# shellcheck disable=SC2154
	local build_dir="${tool_dir}/builddir"

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--build-dir) build_dir="$2"; shift 2 ;;
			--) shift; break ;;
			*) break ;;
		esac
	done

	log_info "Building with Meson..."
	meson compile -C "$build_dir" "$@"
}
