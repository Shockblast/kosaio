# === METADATA ===
KOSAIO_TOOL_ID="toolchain"
KOSAIO_TOOL_NAME="Dreamcast Toolchain"
KOSAIO_TOOL_DESC="The compiler suite (GCC/Binutils) for SH4 and ARM architectures."
KOSAIO_TOOL_TAGS=("core" "compiler" "gcc" "sh4" "arm")
KOSAIO_TOOL_TYPE=("core")
KOSAIO_TOOL_DEPS=("bison" "build-essential" "bzip2" "cmake" "curl" "diffutils" "flex" "gawk" "gettext" "git" "libelf-dev" "libgmp-dev" "libisofs-dev" "libjpeg-dev" "libmpc-dev" "libmpfr-dev" "libpng-dev" "make" "meson" "ninja-build" "patch" "pkg-config" "python3" "rake" "sed" "tar" "texinfo" "wget")

# === SOURCE CONTROL ===
KOSAIO_TOOL_REPO=""
KOSAIO_TOOL_BRANCH=""

# === BUILD OPTIONS ===
KOSAIO_TOOL_BUILD_SYSTEM="none"
KOSAIO_TOOL_BUILD_DIR=""
KOSAIO_TOOL_BUILD_SUBDIR="."
KOSAIO_TOOL_TOOLCHAIN=""
KOSAIO_TOOL_ARGS=()

# === INSTALLATION ===
KOSAIO_TOOL_INSTALL_METHOD="none"
KOSAIO_TOOL_BINARIES=()
KOSAIO_TOOL_BINARY_SUBDIR=""
KOSAIO_TOOL_INSTALLATION_FOLDER="${DREAMCAST_SDK}"
KOSAIO_TOOL_INSTALLATION_LIBDIR=""
KOSAIO_TOOL_INSTALLATION_INCLUDEDIR=""

# === PATCHES ===
KOSAIO_TOOL_PATCHES=("toolchain")

# === UNINSTALL & HEALTH ===
KOSAIO_TOOL_LIBS=(
    "${DREAMCAST_SDK}/sh-elf/bin/sh-elf-gcc"
)
KOSAIO_TOOL_INCLUDE_DIRS=()

# === RICH MESSAGING ===
KOSAIO_TOOL_INSTALL_CONFIRM=false
KOSAIO_TOOL_POSTINSTALL_MESSAGE=""
KOSAIO_TOOL_BUILD_WARNING=()
KOSAIO_TOOL_INSTALL_WARNING=()
KOSAIO_TOOL_INFO_EXTRA=()
