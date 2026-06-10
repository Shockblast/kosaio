# === METADATA ===
KOSAIO_TOOL_ID="dcload-ip"
KOSAIO_TOOL_NAME="dcload-ip"
KOSAIO_TOOL_DESC="Dreamcast Ethernet loader and debug tool"
KOSAIO_TOOL_TAGS=("loader" "ethernet" "ip" "debug")
KOSAIO_TOOL_TYPE=("loader")
KOSAIO_TOOL_DEPS=("build-essential" "git" "libelf-dev")

# === SOURCE CONTROL ===
KOSAIO_TOOL_REPO="https://github.com/KallistiOS/dcload-ip.git"
KOSAIO_TOOL_BRANCH=""

# === BUILD OPTIONS ===
KOSAIO_TOOL_BUILD_SYSTEM="make"
KOSAIO_TOOL_BUILD_DIR=""
KOSAIO_TOOL_BUILD_SUBDIR="host-src/tool"
KOSAIO_TOOL_TOOLCHAIN=""
KOSAIO_TOOL_ARGS=()

# === INSTALLATION ===
KOSAIO_TOOL_INSTALL_METHOD="cp"
KOSAIO_TOOL_BINARIES=("dc-tool-ip")
KOSAIO_TOOL_BINARY_SUBDIR="host-src/tool"
KOSAIO_TOOL_INSTALLATION_FOLDER="${KOSAIO_BIN_PATH}"
KOSAIO_TOOL_INSTALLATION_LIBDIR=""
KOSAIO_TOOL_INSTALLATION_INCLUDEDIR=""

# === PATCHES ===
KOSAIO_TOOL_PATCHES=()

# === UNINSTALL & HEALTH ===
KOSAIO_TOOL_LIBS=(
    "${KOSAIO_BIN_PATH}/dc-tool-ip"
)
KOSAIO_TOOL_INCLUDE_DIRS=()

# === RICH MESSAGING ===
KOSAIO_TOOL_INSTALL_CONFIRM=false
KOSAIO_TOOL_POSTINSTALL_MESSAGE=""
KOSAIO_TOOL_BUILD_WARNING=()
KOSAIO_TOOL_INSTALL_WARNING=()
KOSAIO_TOOL_INFO_EXTRA=(
    "${C_YELLOW}Context:${C_RESET} High-speed code upload via Broadband Adapter."  
    "${C_YELLOW}Tool:${C_RESET}    dc-tool-ip (Host Utility)"
    "${C_YELLOW}Usage:${C_RESET}   dc-tool-ip -t <ip_address> -x <binary.elf>"
)
