#!/bin/bash
# KOSAIO Setup Assistant
# Automates the creation of the Podman/Docker environment for Dreamcast development.

set -e

# Colors for output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}    KOSAIO Environment Setup Tool      ${NC}"
echo -e "${CYAN}========================================${NC}"

# Path Detection
KOSAIO_HOST_DIR="$(cd "$(dirname "$0")" && pwd)"

# 0. Load Configuration File
CONFIG_FILE="${KOSAIO_HOST_DIR}/kosaio.cfg"
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${GREEN}[INFO] Loading configuration from kosaio.cfg${NC}"
    source "$CONFIG_FILE"
fi

# 1. Detect Container Tool
if [ -z "$TOOL" ]; then
    if command -v podman >/dev/null 2>&1; then
        TOOL="podman"
    elif command -v docker >/dev/null 2>&1; then
        TOOL="docker"
    else
        echo -e "${RED}[ERROR] Neither podman nor docker found in PATH.${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}[INFO] Using ${TOOL}.${NC}"

# 2. Path Detection
PARENT_DIR="$(dirname "${KOSAIO_HOST_DIR}")"

echo -e "\n${YELLOW}--- Path Configuration ---${NC}"
echo -e "KOSAIO Location: ${KOSAIO_HOST_DIR}"

# Determine Projects Directory
if [ -z "$PROJECTS_HOST_DIR" ]; then
    DEFAULT_PROJECTS_DIR="${PARENT_DIR}"
    echo -en "Enter your PROJECTS directory [${DEFAULT_PROJECTS_DIR}]: "
    read PROJECTS_HOST_DIR
    PROJECTS_HOST_DIR="${PROJECTS_HOST_DIR:-${DEFAULT_PROJECTS_DIR}}"
fi

# Ensure absolute path
PROJECTS_HOST_DIR="$(cd "${PROJECTS_HOST_DIR}" && pwd)"
echo -e "${GREEN}[OK] Projects mapped to: ${PROJECTS_HOST_DIR}${NC}"

# 3. Build Image
echo -e "\n${YELLOW}--- Building Image ---${NC}"
IMAGE_NAME="shockblast/kosaio"

if [[ "$("${TOOL}" images -q "${IMAGE_NAME}" 2> /dev/null)" == "" ]]; then
    echo -e "Building image ${IMAGE_NAME} from local Dockerfile..."
    "${TOOL}" build -t "${IMAGE_NAME}" -f "${KOSAIO_HOST_DIR}/docker/Dockerfile" "${KOSAIO_HOST_DIR}/docker"
else
    echo -e "Image ${IMAGE_NAME} already exists. Skipping build."
fi

# 4. Container Creation
echo -e "\n${YELLOW}--- Container Management ---${NC}"
CONTAINER_NAME="${CONTAINER_NAME:-kosaio}"

# Check if container exists
if "${TOOL}" ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${YELLOW}[WARN] Container '${CONTAINER_NAME}' already exists.${NC}"
    echo -en "Do you want to REMOVE and recreate it? (y/n): "
    read REMOVE_OLD
    if [[ "$REMOVE_OLD" == "y" || "$REMOVE_OLD" == "Y" ]]; then
        "${TOOL}" rm -f "${CONTAINER_NAME}"
    else
        echo -e "${GREEN}[INFO] Using existing container.${NC}"
        echo -e "To enter: ${TOOL} exec -it ${CONTAINER_NAME} /bin/bash"
        exit 0
    fi
fi

# Determine mount options (SELinux)
MOUNT_Z=""
if [[ "${TOOL}" == "podman" ]]; then
    MOUNT_Z=":Z"
fi

echo -e "Creating container '${CONTAINER_NAME}'..."
"${TOOL}" run -d \
    --name "${CONTAINER_NAME}" \
    -v "${KOSAIO_HOST_DIR}:/opt/kosaio${MOUNT_Z}" \
    -v "${PROJECTS_HOST_DIR}:/opt/projects${MOUNT_Z}" \
    "${IMAGE_NAME}" tail -f /dev/null

# 5. Helper Script
echo -e "\n${YELLOW}--- Finalizing ---${NC}"
SHELL_HELPER="${KOSAIO_HOST_DIR}/kosaio-shell"
cat <<EOF > "${SHELL_HELPER}"
#!/bin/bash
# Simple helper to enter the KOSAIO container
${TOOL} exec -it ${CONTAINER_NAME} /bin/bash
EOF
chmod +x "${SHELL_HELPER}"

echo -e "${GREEN}[SUCCESS] KOSAIO environment is ready!${NC}"
echo -e "You can now enter the container by running:"
echo -e "  ${CYAN}./kosaio-shell${NC}"
echo -e "\nInside the container, try:"
echo -e "  ${CYAN}kosaio diagnose system${NC}"
echo -e "${CYAN}========================================${NC}"
