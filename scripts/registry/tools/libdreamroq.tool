# === METADATA ===
KOSAIO_TOOL_ID="libdreamroq"
KOSAIO_TOOL_NAME="libdreamroq"
KOSAIO_TOOL_DESC="RoQ playback library for Dreamcast"
KOSAIO_TOOL_TAGS=("video" "roq" "multimedia" "library")
KOSAIO_TOOL_TYPE=("lib")
KOSAIO_TOOL_DEPS=("build-essential" "git")

# === SOURCE CONTROL ===
KOSAIO_TOOL_REPO="https://github.com/Shockblast/libdreamroq.git"
KOSAIO_TOOL_BRANCH=""

# === BUILD OPTIONS ===
KOSAIO_TOOL_BUILD_SYSTEM="make"
KOSAIO_TOOL_BUILD_DIR=""
KOSAIO_TOOL_BUILD_SUBDIR="."
# Only builds the static library locally; installation into KOS addons is
# handled by the tool hook (kosaio_tool_apply).
KOSAIO_TOOL_BUILD_TARGET="build"
KOSAIO_TOOL_TOOLCHAIN=""
KOSAIO_TOOL_ARGS=()

# === INSTALLATION ===
# The hook copies the library + headers into ${KOS_BASE}/addons.
KOSAIO_TOOL_INSTALL_METHOD="none"
KOSAIO_TOOL_BINARIES=()
KOSAIO_TOOL_BINARY_SUBDIR=""
KOSAIO_TOOL_INSTALLATION_FOLDER="${KOS_BASE}/addons"
KOSAIO_TOOL_INSTALLATION_LIBDIR="lib/dreamcast"
KOSAIO_TOOL_INSTALLATION_INCLUDEDIR="include/dreamroq"

# === PATCHES ===
KOSAIO_TOOL_PATCHES=()

# === UNINSTALL & HEALTH ===
KOSAIO_TOOL_CAN_MAKE_CLEAN=true
KOSAIO_TOOL_LIBS=(
    "${KOS_BASE}/addons/lib/dreamcast/libdreamroq.a"
)
KOSAIO_TOOL_INCLUDE_DIRS=(
    "${KOS_BASE}/addons/include/dreamroq"
)

# === RICH MESSAGING ===
KOSAIO_TOOL_INSTALL_CONFIRM=false
KOSAIO_TOOL_POSTINSTALL_MESSAGE=""
KOSAIO_TOOL_BUILD_WARNING=()
KOSAIO_TOOL_INSTALL_WARNING=()
KOSAIO_TOOL_INFO_EXTRA=(
    "${C_YELLOW}Context:${C_RESET} High performance RoQ video decoding for Dreamcast."
    "${C_YELLOW}Usage:${C_RESET}   ${C_CYAN}#include <dreamroq/dreamroqlib.h>${C_RESET} + ${C_CYAN}-ldreamroq${C_RESET}."
)
