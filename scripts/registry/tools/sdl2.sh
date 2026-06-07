#!/bin/bash
set -Eeuo pipefail

# scripts/registry/tools/sdl2.sh
# Manifest for SDL2 (Vanilla - container GCC)

ID="sdl2"
NAME="SDL2"
DESC="Simple DirectMedia Layer 2 - cross-platform multimedia library"
TAGS="sdl,sdl2,multimedia,video,audio,library"
TYPE="lib"
DEPS="build-essential git"

function reg_check_health() {
    [ -d "/usr/local/include/SDL2" ] || return 2
    [ -f "/usr/local/include/SDL2/SDL.h" ] || return 2
    return 0
}

function reg_info() {
    local tool_dir=$(validate_get_tool_path "$ID")
    local status="${C_RED}Not Compiled${C_RESET}"

    if [ -f "/usr/local/include/SDL2/SDL.h" ]; then
        status="${C_GREEN}Compiled${C_RESET}"
    fi

    log_box --info "${NAME}: Cross-platform Multimedia Library" \
        "${C_YELLOW}Status:${C_RESET}  ${status}" \
        "${C_YELLOW}Path:${C_RESET}    ${tool_dir}" \
        "${C_YELLOW}Usage:${C_RESET}   Add ${C_CYAN}-lSDL2${C_RESET} to your Makefile." \
        "${C_YELLOW}Flags:${C_RESET}   ${C_CYAN}--no-audio${C_RESET}, ${C_CYAN}--no-joystick${C_RESET}, ${C_CYAN}--no-opengl${C_RESET}, ${C_CYAN}--no-haptic${C_RESET}," \
        "             ${C_CYAN}--no-pthreads${C_RESET}, ${C_CYAN}--no-timers${C_RESET}, ${C_CYAN}--no-events${C_RESET}, ${C_CYAN}--no-render${C_RESET}," \
        "             ${C_CYAN}--no-tests${C_RESET}, ${C_CYAN}--static${C_RESET}" \
        "${C_YELLOW}Docs:${C_RESET}    See ${C_CYAN}readme.md${C_RESET} for full flag descriptions."
}

function reg_clone() {
    local tool_dir=$(validate_get_tool_path "$ID")
    log_info --draw-line "Cloning ${NAME}..."
    kosaio_git_clone --branch SDL2 https://github.com/libsdl-org/SDL.git "${tool_dir}"
}

function reg_build() {
    local tool_dir=$(validate_get_tool_path "$ID")
    [ -d "$tool_dir" ] || { log_error "${NAME} source missing. Run 'kosaio clone ${ID}' first."; return 1; }

    kosaio_translate_sdl_args "configure" "$@"
    local build_args=("${KOSAIO_TRANSLATED_ARGS[@]}")

    log_info --draw-line "Building ${NAME}..."
    (
        cd "$tool_dir"
        ./configure --prefix=/usr/local "${build_args[@]}"
        make -j$(nproc)
        make install
    )
}

function reg_apply() {
    log_success "${NAME} is ready at /usr/local."
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
    if [ -d "$tool_dir" ]; then
        (cd "$tool_dir" && make uninstall 2>/dev/null) || true
    fi
    rm -rf /usr/local/include/SDL2
    rm -f /usr/local/lib/libSDL2*
    rm -rf /usr/local/lib/cmake/SDL2
    rm -f /usr/local/lib/pkgconfig/sdl2.pc
    rm -f /usr/local/bin/sdl2-config
    rm -rf "$tool_dir"
    log_success "${NAME} removed."
}

function reg_update() {
    local tool_dir=$(validate_get_tool_path "$ID")
    kosaio_standard_update_flow "${ID}" "${NAME}" "$tool_dir" "$@"
}

function reg_clean() {
    local tool_dir=$(validate_get_tool_path "$ID")
    [ -d "$tool_dir" ] && (cd "$tool_dir" && make clean 2>/dev/null || true)
    log_success "${NAME} cleaned."
}
