# === METADATA ===
KOSAIO_TOOL_ID="sdl3-dc"
KOSAIO_TOOL_NAME="SDL3-DC"
KOSAIO_TOOL_DESC="SDL3 port for Dreamcast by GPF"
KOSAIO_TOOL_TAGS=("sdl" "sdl3" "dreamcast" "gpf" "library" "video" "audio")
KOSAIO_TOOL_TYPE=("lib")
KOSAIO_TOOL_DEPS=("build-essential" "git" "cmake")

# === SOURCE CONTROL ===
KOSAIO_TOOL_REPO="https://github.com/GPF/SDL.git"
KOSAIO_TOOL_BRANCH="dreamcastSDL3"

# === BUILD OPTIONS ===
KOSAIO_TOOL_BUILD_SYSTEM="cmake"
KOSAIO_TOOL_BUILD_DIR="dcbuild"
KOSAIO_TOOL_BUILD_SUBDIR=""
KOSAIO_TOOL_TOOLCHAIN="${KOS_BASE}/utils/cmake/kallistios.toolchain.cmake"
KOSAIO_TOOL_ARGS=()

# === INSTALLATION ===
KOSAIO_TOOL_INSTALL_METHOD="cmake_install"
KOSAIO_TOOL_BINARIES=()
KOSAIO_TOOL_BINARY_SUBDIR=""
KOSAIO_TOOL_INSTALLATION_FOLDER="${KOS_BASE}/addons"
KOSAIO_TOOL_INSTALLATION_LIBDIR="lib/dreamcast"
KOSAIO_TOOL_INSTALLATION_INCLUDEDIR="include/"

# === PATCHES ===
KOSAIO_TOOL_PATCHES=()

# === UNINSTALL & HEALTH ===
KOSAIO_TOOL_LIBS=(
    "${KOS_BASE}/addons/lib/dreamcast/libSDL3.a"
    "${KOS_BASE}/addons/lib/dreamcast/libSDL3main.a"
    "${KOS_BASE}/addons/lib/dreamcast/libSDL3_test.a"
)
KOSAIO_TOOL_INCLUDE_DIRS=(
    "${KOS_BASE}/addons/include/SDL3"
)

# === RICH MESSAGING ===
KOSAIO_TOOL_INSTALL_CONFIRM=true
KOSAIO_TOOL_POSTINSTALL_MESSAGE=""
KOSAIO_TOOL_BUILD_WARNING=()
KOSAIO_TOOL_INSTALL_WARNING=(
    "CUSTOMIZABLE BUILD"
    "${C_YELLOW}Tip:${C_RESET} Edit build options with ${C_CYAN}kosaio config sdl3-dc${C_RESET}."
    "Proceeding will use standard defaults."
)
KOSAIO_TOOL_INFO_EXTRA=(
    "${C_YELLOW}Context:${C_RESET} SDL3 port for Dreamcast by GPF."
    "${C_YELLOW}Usage:${C_RESET}   Add ${C_CYAN}-lSDL3${C_RESET} to your Makefile."
)
