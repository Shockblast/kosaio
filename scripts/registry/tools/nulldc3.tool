# === METADATA ===
KOSAIO_TOOL_ID="nulldc3"
KOSAIO_TOOL_NAME="nullDC 3"
KOSAIO_TOOL_DESC="Reference Dreamcast emulator for development (SH4 JIT+interpreter, reference renderers, reios, integrated debugger, headless runs)"
KOSAIO_TOOL_TAGS=("emulator" "testing" "reference" "debugger" "headless")
KOSAIO_TOOL_TYPE=("emulator")
KOSAIO_TOOL_DEPS=("cmake" "ninja-build" "build-essential" "git" "pkg-config" "libx11-dev" "libxext-dev" "libgl1-mesa-dev" "libasound2-dev" "libpulse-dev" "libevdev-dev" "libudev-dev" "libcurl4-openssl-dev")

# === SOURCE CONTROL ===
KOSAIO_TOOL_REPO="https://github.com/skmp/nulldc3.git"
KOSAIO_TOOL_BRANCH="main"
KOSAIO_TOOL_CLONE_RECURSIVE=false

# === BUILD OPTIONS ===
KOSAIO_TOOL_BUILD_SYSTEM="cmake"
KOSAIO_TOOL_BUILD_DIR="build"
KOSAIO_TOOL_BUILD_SUBDIR=""
KOSAIO_TOOL_TOOLCHAIN=""
KOSAIO_TOOL_ARGS=()

# === INSTALLATION ===
KOSAIO_TOOL_INSTALL_METHOD="cp"
KOSAIO_TOOL_BINARIES=("nulldc3")
KOSAIO_TOOL_BINARY_SUBDIR="build"
KOSAIO_TOOL_INSTALLATION_FOLDER="${KOSAIO_DIR}/data/repos/nulldc3"
KOSAIO_TOOL_INSTALLATION_LIBDIR=""
KOSAIO_TOOL_INSTALLATION_INCLUDEDIR=""

# === PATCHES ===
KOSAIO_TOOL_PATCHES=()

# === UNINSTALL & HEALTH ===
KOSAIO_TOOL_LIBS=(
    "${KOSAIO_DIR}/data/repos/nulldc3/build/nulldc3"
)
KOSAIO_TOOL_INCLUDE_DIRS=()

# === RICH MESSAGING ===
KOSAIO_TOOL_INSTALL_CONFIRM=false
KOSAIO_TOOL_POSTINSTALL_MESSAGE=""
KOSAIO_TOOL_BUILD_WARNING=()
KOSAIO_TOOL_INSTALL_WARNING=()
KOSAIO_TOOL_INFO_EXTRA=(
    "${C_YELLOW}Context:${C_RESET} Reference emulator for Dreamcast development (fork of reicast)."
    "${C_YELLOW}Build:${C_RESET}   Uses ${C_CYAN}CMake + Ninja${C_RESET}, embeds the Dreamcast DevTools web UI (needs Node.js 22+)"
    "${C_YELLOW}Headless:${C_RESET} nulldc3 --config config:Headless=yes , config:Exit.AfterVblanks=600 , config:Exit.StateHash=yes <game.elf>"
    "${C_YELLOW}BIOS:${C_RESET}    Optional (reios built-in); dc_boot.bin + dc_flash.bin go in data/ for full boot"
    "${C_YELLOW}Config:${C_RESET}  Edit with ${C_CYAN}kosaio config nulldc3${C_RESET} (TA LLE/HLE, debugger, interpreters-only)"
)
