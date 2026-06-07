#!/bin/bash
set -Eeuo pipefail

# scripts/registry/tools/sdl2-dc.sh
# Manifest for SDL2 Dreamcast (GPF fork)

ID="sdl2-dc"
NAME="SDL2-DC"
DESC="SDL2 port for Dreamcast by GPF"
TAGS="sdl,sdl2,dreamcast,gpf,library,video,audio"
TYPE="lib"
DEPS="build-essential git cmake"

function reg_check_health() {
    [ -n "${KOS_BASE:-}" ] || return 3
    [ -f "${KOS_BASE}/addons/lib/dreamcast/libSDL2.a" ] || return 2
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

    log_box --info "${NAME}: SDL2 for Dreamcast" \
        "${C_YELLOW}Context:${C_RESET} High performance SDL2 port for Dreamcast by GPF." \
        "${C_YELLOW}Status:${C_RESET}  ${status}" \
        "${C_YELLOW}KOS_BASE:${C_RESET} ${kos_status}" \
        "${C_YELLOW}Path:${C_RESET}    ${tool_dir}" \
        "${C_YELLOW}Usage:${C_RESET}   Add ${C_CYAN}-lSDL2${C_RESET} to your Makefile." \
        "${C_YELLOW}Flags:${C_RESET}   ${C_CYAN}--no-audio${C_RESET}, ${C_CYAN}--no-joystick${C_RESET}, ${C_CYAN}--no-opengl${C_RESET}, ${C_CYAN}--no-haptic${C_RESET}," \
        "             ${C_CYAN}--no-pthreads${C_RESET}, ${C_CYAN}--no-timers${C_RESET}, ${C_CYAN}--no-events${C_RESET}, ${C_CYAN}--no-render${C_RESET}," \
        "             ${C_CYAN}--no-tests${C_RESET}, ${C_CYAN}--static${C_RESET}, ${C_CYAN}--gpf-settings${C_RESET}" \
        "${C_YELLOW}Docs:${C_RESET}    See ${C_CYAN}readme.md${C_RESET} for full flag descriptions."
}

function reg_clone() {
    local tool_dir=$(validate_get_tool_path "$ID")
    log_info --draw-line "Cloning ${NAME}..."
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

    kosaio_translate_sdl_args "cmake" "$@"
    local build_args=("${KOSAIO_TRANSLATED_ARGS[@]}")

    log_info --draw-line "Building ${NAME}..."

    local build_dir="${tool_dir}/dcbuild"
    mkdir -p "${build_dir}"

    (
        cd "${build_dir}"
        cmake -DCMAKE_TOOLCHAIN_FILE="$toolchain" \
              -G "Unix Makefiles" \
              -DSDL_OPENGL=ON \
              -DSDL_HAPTIC=ON \
              -DSDL_TESTS=OFF \
              -DSDL_PTHREADS=ON \
              -DSDL_TIMER_UNIX=ON \
              -DCMAKE_INSTALL_PREFIX="${KOS_BASE}/addons" \
              -DCMAKE_INSTALL_LIBDIR="lib/dreamcast" \
              -DCMAKE_INSTALL_INCLUDEDIR="include/" \
              "${build_args[@]}" \
              ".."

        make -j$(nproc) install
    )
}

function reg_apply() {
    log_success "${NAME} is ready in KOS addons."
}

function reg_install() {
    if [ -z "${KOSAIO_NON_INTERACTIVE:-}" ]; then
        log_box --type=warn "CUSTOMIZABLE BUILD" \
            "${C_YELLOW}Tip:${C_RESET} Run ${C_CYAN}kosaio clone ${ID}${C_RESET} first to inspect sources," \
            "then use ${C_CYAN}kosaio build ${ID}${C_RESET} with custom flags like ${C_CYAN}--no-audio${C_RESET}." \
            "Run ${C_CYAN}kosaio info ${ID}${C_RESET} for available build options." \
            "Proceeding will use standard defaults."
        confirm "Continue with default installation?" || return 1
    fi
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
