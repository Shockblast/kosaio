# === METADATA ===
KOSAIO_TOOL_ID="nitrocast"
KOSAIO_TOOL_NAME="nitrocast"
KOSAIO_TOOL_DESC="Modern, fast Dreamcast emulator (old lxdream-nitro)"
KOSAIO_TOOL_TAGS=("emulator" "testing" "graphics" "vulkan" "opengl" "gdb")
KOSAIO_TOOL_TYPE=("emulator")
KOSAIO_TOOL_DEPS=("libgtk-3-dev" "libopenal-dev" "libpng-dev" "libgl1-mesa-dev" "zlib1g-dev" "meson" "ninja-build" "git" "build-essential")

# === SOURCE CONTROL ===
KOSAIO_TOOL_REPO="https://gitlab.com/simulant/community/lxdream-nitro.git"
KOSAIO_TOOL_BRANCH=""
KOSAIO_TOOL_CLONE_RECURSIVE=true

# === BUILD OPTIONS ===
KOSAIO_TOOL_BUILD_SYSTEM="meson"
KOSAIO_TOOL_BUILD_DIR="build"
KOSAIO_TOOL_BUILD_SUBDIR="."
KOSAIO_TOOL_TOOLCHAIN=""
KOSAIO_TOOL_MESON_CLEAN_BUILD=true
KOSAIO_TOOL_ARGS=()

# === INSTALLATION ===
KOSAIO_TOOL_INSTALL_METHOD="none"
KOSAIO_TOOL_BINARIES=("nitrocast")
KOSAIO_TOOL_BINARY_SUBDIR="build"
KOSAIO_TOOL_INSTALLATION_FOLDER="${KOSAIO_DIR}/data/repos/nitrocast"
KOSAIO_TOOL_INSTALLATION_LIBDIR=""
KOSAIO_TOOL_INSTALLATION_INCLUDEDIR=""

# === PATCHES ===
KOSAIO_TOOL_PATCHES=()

# === UNINSTALL & HEALTH ===
KOSAIO_TOOL_LIBS=(
    "${KOSAIO_DIR}/data/repos/nitrocast/build/nitrocast"
)
KOSAIO_TOOL_INCLUDE_DIRS=()

# === RICH MESSAGING ===
KOSAIO_TOOL_INSTALL_CONFIRM=false
KOSAIO_TOOL_POSTINSTALL_MESSAGE=""
KOSAIO_TOOL_BUILD_WARNING=()
KOSAIO_TOOL_INSTALL_WARNING=()
KOSAIO_TOOL_INFO_EXTRA=(
    "${C_YELLOW}Context:${C_RESET} Dreamcast emulator for debugging and testing."
    "${C_YELLOW}Build:${C_RESET}   Uses ${C_CYAN}Meson + Ninja${C_RESET}"
    "${C_YELLOW}Note:${C_RESET}    Excellent for homebrew development."
)
