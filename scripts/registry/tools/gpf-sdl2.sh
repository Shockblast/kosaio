#!/bin/bash
set -Eeuo pipefail

# scripts/registry/tools/gpf-sdl2.sh
# Manifest for GPF's SDL2 port for Dreamcast

ID="gpf-sdl2"
NAME="GPF-SDL2"
DESC="GPF's SDL2 port for Dreamcast (Modern/SDL2)"
TAGS="sdl,sdl2,gpf,library,video,audio"
TYPE="lib"
DEPS="build-essential git cmake"

function reg_check_health() {
	# 1. Require KOS_BASE
	[ -n "${KOS_BASE:-}" ] || return 3
    
	# 2. Check for the compiled library in addons
	[ -f "${KOS_BASE}/addons/lib/dreamcast/libSDL2.a" ] || return 2
	
	# 3. Check for headers
	[ -d "${KOS_BASE}/addons/include/SDL2" ] || return 2
	
	return 0
}

function reg_info() {
	local tool_dir=$(validate_get_tool_path "$ID")
	local status="${C_RED}Not Compiled${C_RESET}"
	local kos_status="${C_GREEN}Found${C_RESET}"
	
	if [ -z "${KOS_BASE:-}" ]; then
		kos_status="${C_RED}MISSING${C_RESET}"
	fi

	if [ -f "${KOS_BASE}/addons/lib/dreamcast/libSDL2.a" ]; then
		status="${C_GREEN}Compiled${C_RESET}"
	fi
	
	log_box --info "${NAME}: SDL2 Video/Audio Library" \
		"${C_YELLOW}Context:${C_RESET} High performance SDL2 port for Dreamcast by GPF." \
		"${C_YELLOW}Status:${C_RESET}  ${status}" \
		"${C_YELLOW}KOS_BASE:${C_RESET} ${kos_status}" \
		"${C_YELLOW}Path:${C_RESET}    ${tool_dir}" \
		"${C_YELLOW}Usage:${C_RESET}   Add ${C_CYAN}-lSDL2${C_RESET} to your Makefile."
}

function reg_clone() {
	local tool_dir=$(validate_get_tool_path "$ID")
	log_info --draw-line "Cloning ${NAME} into extras..."
	kosaio_git_clone --branch dreamcastSDL2 https://github.com/GPF/SDL.git "${tool_dir}"
}

function reg_build() {
	local tool_dir=$(validate_get_tool_path "$ID")
	[ -d "$tool_dir" ] || { log_error "${NAME} source missing. Run 'kosaio clone ${ID}' first."; return 1; }
	
	if [ -z "${KOS_BASE:-}" ]; then
		log_error "KOS_BASE is not set. KOS environment must be loaded to build ${NAME}."
		return 1
	fi

    local toolchain="${KOS_BASE}/utils/cmake/dreamcast.toolchain.cmake"
    if [ ! -f "$toolchain" ]; then
        log_error "KOS CMake toolchain not found at: $toolchain"
        log_info "Make sure your KOS installation is up to date."
        return 1
    fi

	log_info --draw-line "Building ${NAME}..."
	
    local build_dir="${tool_dir}/dcbuild"
    mkdir -p "${build_dir}"

    (
        cd "${build_dir}"
        # We follow the options from build-scripts/dreamcast.sh but integrated here
        cmake -DCMAKE_TOOLCHAIN_FILE="$toolchain" \
              -G "Unix Makefiles" \
              -DSDL_OPENGL=ON \
              -DSDL_HAPTIC=ON \
              -DSDL_TESTS=OFF \
              -DSDL_PTHREADS=OFF \
              -DSDL_TIMER_UNIX=OFF \
              -DCMAKE_INSTALL_PREFIX="${KOS_BASE}/addons" \
              -DCMAKE_INSTALL_LIBDIR="lib/dreamcast" \
              -DCMAKE_INSTALL_INCLUDEDIR="include/" \
              ".."
        
        make -j$(nproc) install
    )
}

function reg_apply() {
	log_success "${NAME} is ready in KOS addons."
}

function reg_install() {
	reg_clone
	reg_build
	reg_apply
	log_success "${NAME} installation complete."
}

function reg_uninstall() {
	local tool_dir=$(validate_get_tool_path "$ID")
	log_info "Removing ${NAME} files..."
    rm -rf "${KOS_BASE}/addons/include/SDL2"
    rm -f "${KOS_BASE}/addons/lib/dreamcast/libSDL2.a"
    rm -f "${KOS_BASE}/addons/lib/dreamcast/libSDL2main.a"
	rm -rf "$tool_dir"
	log_success "${NAME} removed."
}

function reg_update() {
	local tool_dir=$(validate_get_tool_path "$ID")
	kosaio_standard_update_flow "${ID}" "${NAME}" "$tool_dir" "$@"
}

function reg_clean() {
	local tool_dir=$(validate_get_tool_path "$ID")
	[ -d "${tool_dir}/dcbuild" ] && rm -rf "${tool_dir}/dcbuild"
	log_success "${NAME} cleaned."
}
