# === METADATA ===
KOSAIO_TOOL_ID="sdl3"
KOSAIO_TOOL_NAME="SDL3"
KOSAIO_TOOL_DESC="Simple DirectMedia Layer 3 - cross-platform multimedia library"
KOSAIO_TOOL_TAGS=("sdl" "sdl3" "multimedia" "video" "audio" "library")
KOSAIO_TOOL_TYPE=("lib")
KOSAIO_TOOL_DEPS=("build-essential" "git" "cmake")

# === SOURCE CONTROL ===
KOSAIO_TOOL_REPO="https://github.com/libsdl-org/SDL.git"
KOSAIO_TOOL_BRANCH="release-3.4.x"

# === BUILD OPTIONS ===
KOSAIO_TOOL_BUILD_SYSTEM="cmake"
KOSAIO_TOOL_BUILD_DIR="build"
KOSAIO_TOOL_BUILD_SUBDIR=""
KOSAIO_TOOL_TOOLCHAIN=""
KOSAIO_TOOL_PREBUILD_FUNC="kosaio_translate_sdl_args cmake"
KOSAIO_TOOL_ARGS=()

# === INSTALLATION ===
KOSAIO_TOOL_INSTALL_METHOD="cmake_install"
KOSAIO_TOOL_BINARIES=()
KOSAIO_TOOL_BINARY_SUBDIR=""
KOSAIO_TOOL_INSTALLATION_FOLDER="/usr/local"
KOSAIO_TOOL_INSTALLATION_LIBDIR="lib"
KOSAIO_TOOL_INSTALLATION_INCLUDEDIR="include"

# === PATCHES ===
KOSAIO_TOOL_PATCHES=()

# === UNINSTALL & HEALTH ===
KOSAIO_TOOL_LIBS=()
KOSAIO_TOOL_INCLUDE_DIRS=(
    "/usr/local/include/SDL3"
)

# === RICH MESSAGING ===
KOSAIO_TOOL_INSTALL_CONFIRM=true
KOSAIO_TOOL_POSTINSTALL_MESSAGE=""
KOSAIO_TOOL_BUILD_WARNING=()
KOSAIO_TOOL_INSTALL_WARNING=(
    "CUSTOMIZABLE BUILD"
    "${C_YELLOW}Tip:${C_RESET} Edit build options with ${C_CYAN}kosaio config sdl3${C_RESET}."
    "Proceeding will use standard defaults."
)
KOSAIO_TOOL_INFO_EXTRA=(
    "${C_YELLOW}Usage:${C_RESET}   Add ${C_CYAN}-lSDL3${C_RESET} to your Makefile."
)
