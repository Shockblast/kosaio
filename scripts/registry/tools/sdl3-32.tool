# === METADATA ===
KOSAIO_TOOL_ID="sdl3-32"
KOSAIO_TOOL_NAME="SDL3 (32-bit)"
KOSAIO_TOOL_DESC="Simple DirectMedia Layer 3 - cross-platform multimedia library (32-bit build)"
KOSAIO_TOOL_TAGS=("sdl" "sdl3" "multimedia" "video" "audio" "library" "32bit")
KOSAIO_TOOL_TYPE=("lib")
KOSAIO_TOOL_DEPS=("build-essential" "git" "cmake" "gcc-multilib" "g++-multilib")

# === SOURCE CONTROL ===
KOSAIO_TOOL_REPO="https://github.com/libsdl-org/SDL.git"
KOSAIO_TOOL_BRANCH="release-3.4.x"

# === BUILD OPTIONS ===
KOSAIO_TOOL_BUILD_SYSTEM="cmake"
KOSAIO_TOOL_BUILD_DIR="build32"
KOSAIO_TOOL_BUILD_SUBDIR=""
KOSAIO_TOOL_TOOLCHAIN=""
KOSAIO_TOOL_ARGS=(
    -DCMAKE_C_FLAGS=-m32
    -DCMAKE_CXX_FLAGS=-m32
)

# === INSTALLATION ===
KOSAIO_TOOL_INSTALL_METHOD="cmake_install"
KOSAIO_TOOL_BINARIES=()
KOSAIO_TOOL_BINARY_SUBDIR=""
KOSAIO_TOOL_CAN_MAKE_UNINSTALL=true
KOSAIO_TOOL_MAKE_ARGS=()
KOSAIO_TOOL_INSTALLATION_FOLDER="/opt/kosaio/data"
KOSAIO_TOOL_INSTALLATION_LIBDIR="lib/sdl3/32"
KOSAIO_TOOL_INSTALLATION_INCLUDEDIR="include"

# === PATCHES ===
KOSAIO_TOOL_PATCHES=()

# === UNINSTALL & HEALTH ===
KOSAIO_TOOL_LIBS=(
    "/opt/kosaio/data/lib/sdl3/32/libSDL3-0.so"
    "/opt/kosaio/data/lib/sdl3/32/libSDL3main.a"
)
KOSAIO_TOOL_INCLUDE_DIRS=(
    "/opt/kosaio/data/include/SDL3"
)

# === RICH MESSAGING ===
KOSAIO_TOOL_INSTALL_CONFIRM=true
KOSAIO_TOOL_POSTINSTALL_MESSAGE=""
KOSAIO_TOOL_BUILD_WARNING=()
KOSAIO_TOOL_INSTALL_WARNING=(
    "CUSTOMIZABLE BUILD"
    "${C_YELLOW}Tip:${C_RESET} Edit build options with ${C_CYAN}kosaio config sdl3-32${C_RESET}."
    "Proceeding will use standard defaults."
)
KOSAIO_TOOL_INFO_EXTRA=(
    "${C_YELLOW}Usage:${C_RESET}   Add ${C_CYAN}-lSDL3${C_RESET} to your Makefile."
    "Install path: ${C_CYAN}/opt/kosaio/data/lib/sdl3/32/${C_RESET}"
)
