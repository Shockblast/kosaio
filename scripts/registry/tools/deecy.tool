# === METADATA ===
KOSAIO_TOOL_ID="deecy"
KOSAIO_TOOL_NAME="Deecy"
KOSAIO_TOOL_DESC="Experimental Dreamcast emulator written in Zig (SH-4 JIT, WebGPU)"
KOSAIO_TOOL_TAGS=("emulator" "testing" "graphics" "webgpu" "vulkan")
KOSAIO_TOOL_TYPE=("emulator")
KOSAIO_TOOL_DEPS=("libgtk-3-dev" "libudev-dev" "git" "build-essential")

# === SOURCE CONTROL ===
KOSAIO_TOOL_REPO="https://github.com/Senryoku/Deecy.git"
KOSAIO_TOOL_BRANCH="main"
KOSAIO_TOOL_CLONE_RECURSIVE=false

# === BUILD OPTIONS ===
KOSAIO_TOOL_BUILD_SYSTEM="zig"
KOSAIO_TOOL_BUILD_DIR="zig-out"
KOSAIO_TOOL_BUILD_SUBDIR="."
KOSAIO_TOOL_TOOLCHAIN=""
KOSAIO_TOOL_ARGS=()

# === INSTALLATION ===
KOSAIO_TOOL_INSTALL_METHOD="cp"
KOSAIO_TOOL_BINARIES=("Deecy")
KOSAIO_TOOL_BINARY_SUBDIR="zig-out/bin"
KOSAIO_TOOL_INSTALLATION_FOLDER="${KOSAIO_DIR}/data/repos/deecy"
KOSAIO_TOOL_INSTALLATION_LIBDIR=""
KOSAIO_TOOL_INSTALLATION_INCLUDEDIR=""

# === PATCHES ===
KOSAIO_TOOL_PATCHES=()

# === UNINSTALL & HEALTH ===
KOSAIO_TOOL_LIBS=(
    "${KOSAIO_DIR}/data/repos/deecy/Deecy"
)
KOSAIO_TOOL_INCLUDE_DIRS=()

# === RICH MESSAGING ===
KOSAIO_TOOL_INSTALL_CONFIRM=false
KOSAIO_TOOL_POSTINSTALL_MESSAGE="Remember to place dc_boot.bin (2 MiB) and dc_flash.bin (128 KiB) in the 'data' folder next to the Deecy binary, or use -Ddata_path=<path> in the config."
KOSAIO_TOOL_BUILD_WARNING=()
KOSAIO_TOOL_INSTALL_WARNING=()
KOSAIO_TOOL_INFO_EXTRA=(
    "${C_YELLOW}Context:${C_RESET} Experimental Dreamcast emulator by Senryoku."
    "${C_YELLOW}Build:${C_RESET}   Uses ${C_CYAN}Zig Build${C_RESET} (zig build)"
    "${C_YELLOW}GPU:${C_RESET}     WebGPU via Dawn (Vulkan/DX12/Metal backends)"
    "${C_YELLOW}Note:${C_RESET}    Zig version auto-detected from repo's .zigversion"
    "${C_YELLOW}BIOS:${C_RESET}    Needs dc_boot.bin + dc_flash.bin to run"
    "${C_YELLOW}SCIF:${C_RESET}    Run with --scif for dcload-serial support (see deecy.cfg)"
)
