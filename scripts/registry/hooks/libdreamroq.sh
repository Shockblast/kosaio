#!/bin/bash
# scripts/registry/hooks/libdreamroq.sh
# Tool hooks for libdreamroq: build with the KOS toolchain and install the
# static library + headers into ${KOS_BASE}/addons (no kos-ports dependency).
# Loaded automatically by helper_loader.sh

# Ensure the KOS SDK is available before building/installing.
kosaio_libdreamroq_require_kos() {
	if [ -z "${KOS_BASE:-}" ] || [ ! -d "${KOS_BASE}" ]; then
		log_error "KOS_BASE is not set. Install the SDK core first: kosaio install kos"
		return 1
	fi

	if ! kosaio_kos_find_env_file "${KOS_BASE}" > /dev/null; then
		log_error "KOS environment file not found in ${KOS_BASE}. Run 'kosaio install kos' first."
		return 1
	fi

	return 0
}

# Run a make target inside the source tree with the KOS environment loaded.
kosaio_libdreamroq_make() {
	local tool_dir=$(__get_tool_dir)

	(
		cd "$tool_dir" || exit 1
		# shellcheck source=/dev/null
		kosaio_kos_source_env "${KOS_BASE}" || exit 1
		make "$@"
	)
}

# Remove leftovers from the previous kos-ports based installation (idempotent).
kosaio_libdreamroq_cleanup_legacy() {
	# Header symlink written into the core KOS include dir by the old
	# upstream Makefile (create_kos_link). Headers now live in addons/include.
	if [ -n "${KOS_BASE:-}" ] && [ -L "${KOS_BASE}/include/dreamroq" ]; then
		rm -f "${KOS_BASE}/include/dreamroq"
		log_info "Removed legacy header link: ${KOS_BASE}/include/dreamroq"
	fi

	if [ -n "${KOS_PORTS:-}" ]; then
		# Header symlink managed by the old KOS_PORTS integration.
		if [ -L "${KOS_PORTS}/include/dreamroq" ]; then
			rm -f "${KOS_PORTS}/include/dreamroq"
			log_info "Removed legacy header link: ${KOS_PORTS}/include/dreamroq"
		fi

		# Old source clone (and its build artifacts) inside kos-ports.
		if [ -d "${KOS_PORTS}/libdreamroq" ]; then
			rm -rf "${KOS_PORTS}/libdreamroq"
			log_info "Removed legacy kos-ports source: ${KOS_PORTS}/libdreamroq"
		fi
	fi
}

kosaio_tool_info() {
	local tool_dir=$(__get_tool_dir)
	local lib="${KOS_BASE}/addons/lib/dreamcast/libdreamroq.a"
	local inc_dir="${KOS_BASE}/addons/include/dreamroq"

	local status="${C_RED}Not Installed${C_RESET}"
	if [ -f "$lib" ] && [ -d "$inc_dir" ]; then
		status="${C_GREEN}Installed${C_RESET}"
	elif [ -f "${tool_dir}/libdreamroq.a" ]; then
		status="${C_YELLOW}Compiled (not installed)${C_RESET}"
	fi

	log_box --info "libdreamroq: RoQ Video Library" \
		"${C_YELLOW}Context:${C_RESET} High performance RoQ video decoding for Dreamcast." \
		"${C_YELLOW}Status:${C_RESET}  ${status}" \
		"${C_YELLOW}Source:${C_RESET}  ${tool_dir}" \
		"${C_YELLOW}Addons:${C_RESET}  ${KOS_BASE}/addons" \
		"${C_YELLOW}Usage:${C_RESET}   ${C_CYAN}#include <dreamroq/dreamroqlib.h>${C_RESET} + ${C_CYAN}-ldreamroq${C_RESET}."
}

kosaio_tool_build() {
	local tool_dir=$(__get_tool_dir)

	[ -d "$tool_dir" ] || { log_error "libdreamroq source missing. Run 'kosaio clone ${ID}' first."; return 1; }

	kosaio_libdreamroq_require_kos || return 1

	log_info --draw-line "Building libdreamroq..."

	kosaio_libdreamroq_make build
}

kosaio_tool_apply() {
	local tool_dir=$(__get_tool_dir)

	kosaio_libdreamroq_require_kos || return 1

	log_info "Installing libdreamroq into KOS addons..."

	# Prefer the project's own install target. Fall back to a plain copy for
	# older checkouts that predate it.
	if grep -qE '^install:' "${tool_dir}/Makefile" 2>/dev/null; then
		kosaio_libdreamroq_make install
	else
		log_info "Makefile has no 'install' target; copying files directly."
		mkdir -p "${KOS_BASE}/addons/lib/dreamcast" "${KOS_BASE}/addons/include/dreamroq"
		cp -v "${tool_dir}/libdreamroq.a" "${KOS_BASE}/addons/lib/dreamcast/"
		cp -v "${tool_dir}/include/"*.h "${KOS_BASE}/addons/include/dreamroq/"
	fi

	# Drop the old kos-ports integration now that addons is authoritative.
	kosaio_libdreamroq_cleanup_legacy

	log_box --success "LIBDREAMROQ: INSTALLATION SUCCESSFUL" \
		"Headers: ${C_CYAN}${KOS_BASE}/addons/include/dreamroq/${C_RESET}" \
		"Library: ${C_CYAN}${KOS_BASE}/addons/lib/dreamcast/libdreamroq.a${C_RESET}" \
		"" \
		"${C_YELLOW}To use libdreamroq in your project:${C_RESET}" \
		"  ${C_YELLOW}1.${C_RESET} Include headers: ${C_CYAN}#include <dreamroq/dreamroqlib.h>${C_RESET}" \
		"  ${C_YELLOW}2.${C_RESET} Link library:   ${C_CYAN}-ldreamroq${C_RESET}"
}

kosaio_tool_uninstall() {
	local tool_dir=$(__get_tool_dir)

	log_info "Removing ${NAME}..."

	[ -n "${KOS_BASE:-}" ] && rm -f "${KOS_BASE}/addons/lib/dreamcast/libdreamroq.a"
	[ -n "${KOS_BASE:-}" ] && rm -rf "${KOS_BASE}/addons/include/dreamroq"

	kosaio_libdreamroq_cleanup_legacy

	rm -rf "$tool_dir"
	kosaio_state_unset container "$ID"
	log_success "${NAME} removed."
}
