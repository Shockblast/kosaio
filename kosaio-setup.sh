#!/bin/bash
# KOSAIO Setup Assistant
# Automates the creation of the Podman/Docker environment for Dreamcast development.

set -Eeuo pipefail

# Trap errors
trap 'echo "Error on line $LINENO"' ERR

# Colors for output
if [ -t 1 ]; then
	RED='\033[1;31m'
	GREEN='\033[1;32m'
	YELLOW='\033[1;33m'
	CYAN='\033[1;36m'
	NC='\033[0m' # No Color
else
	RED=''
	GREEN=''
	YELLOW=''
	CYAN=''
	NC=''
fi

# --- Library Sourcing ---
# Source common utilities if available, mainly for logging
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
if [[ -f "${SCRIPT_DIR}/scripts/common/ui.sh" ]]; then
	source "${SCRIPT_DIR}/scripts/common/ui.sh"
else
	# Fallback logging if ui.sh is missing
	function log_info() { echo -e "[INFO] $*"; }
	function log_warn() { echo -e "[WARN] $*"; }
	function log_error() { echo -e "[ERROR] $*" >&2; }
	function kosaio_echo() { echo -e "$*"; }
fi

log_info --draw-line "	KOSAIO Environment Setup Tool	  "

# --- Global Config ---
KOSAIO_HOST_DIR="${SCRIPT_DIR}"
CONFIG_FILE="${KOSAIO_HOST_DIR}/kosaio.cfg"
PROJECTS_HOST_DIR=""
TOOL=""
CONTAINER_NAME="${CONTAINER_NAME:-kosaio}"
IMAGE_NAME="shockblast/kosaio"

# --- Functions ---

function show_help() {
	echo -e "${C_B_CYAN}KOSAIO Setup Assistant${NC}"
	echo -e "Automates the creation of the Dreamcast development environment.\n"
	echo -e "${C_BOLD}USAGE:${NC}"
	echo -e "  ./kosaio-setup.sh [options]\n"
	echo -e "${C_BOLD}OPTIONS:${NC}"
	echo -e "  ${C_CYAN}--install, -i${NC}    Run standard installation (default)"
	echo -e "  ${C_CYAN}--uninstall, -u${NC}  Remove container, image, and helper scripts"
	echo -e "  ${C_CYAN}--rebuild, -r${NC}    Force rebuild of the Docker image"
	echo -e "  ${C_CYAN}--status, -s${NC}     Show current host-side installation status"
	echo -e "  ${C_CYAN}--doctor, -d${NC}     Verify host-side dependencies and configuration"
	echo -e "  ${C_CYAN}--help, -h${NC}       Show this help message\n"
	exit 0
}

function load_config() {
	if [[ -f "$CONFIG_FILE" ]]; then
		log_info "Loading configuration from kosaio.cfg"
		source "$CONFIG_FILE"
	fi
}

function check_container_tool() {
	TOOL="${TOOL:-}"
	if [[ -z "$TOOL" ]]; then
		if command -v podman >/dev/null 2>&1; then
			TOOL="podman"
		elif command -v docker >/dev/null 2>&1; then
			TOOL="docker"
		else
			log_error "Neither podman nor docker found in PATH."
			return 1
		fi
	fi
	export TOOL
}

function status_check() {
	check_container_tool || return 1
	log_info --draw-line "KOSAIO Host Status"
	
	printf "  %-20s: %s\n" "Engine" "${TOOL}"
	
	if "${TOOL}" images -q "${IMAGE_NAME}" >/dev/null 2>&1; then
		printf "  %-20s: ${C_GREEN}EXISTS${NC}\n" "Image"
	else
		printf "  %-20s: ${P_RED}MISSING${NC}\n" "Image"
	fi
	
	if "${TOOL}" ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
		local running_status=$("${TOOL}" inspect -f '{{.State.Running}}' "${CONTAINER_NAME}" 2>/dev/null)
		if [ "$running_status" == "true" ]; then
			printf "  %-20s: ${C_GREEN}RUNNING${NC}\n" "Container"
		else
			printf "  %-20s: ${C_YELLOW}STOPPED${NC}\n" "Container"
		fi
	else
		printf "  %-20s: ${C_RED}MISSING${NC}\n" "Container"
	fi

	[ -f "./kosaio-shell" ] && printf "  %-20s: ${C_GREEN}OK${NC}\n" "Shell Helper" || printf "  %-20s: ${C_RED}MISSING${NC}\n" "Shell Helper"
	echo ""
}

function uninstall_kosaio() {
	check_container_tool || return 1
	log_info --draw-line "Uninstalling KOSAIO..."
	
	if "${TOOL}" ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
		log_info "Removing container '${CONTAINER_NAME}'..."
		"${TOOL}" rm -f "${CONTAINER_NAME}" || true
	fi

	# Flexible image check (handles localhost/ prefix or missing tags)
	if "${TOOL}" images --format "{{.Repository}}:{{.Tag}}" | grep -q "${IMAGE_NAME}"; then
		log_warn "Do you want to remove the Docker image '${IMAGE_NAME}'? (y/n)"
		read -r REMOVE_IMG
		if [[ "$REMOVE_IMG" =~ ^[Yy]$ ]]; then
			log_info "Removing image '${IMAGE_NAME}'..."
			"${TOOL}" rmi "${IMAGE_NAME}" || true
		fi
	fi

	[ -f "./kosaio-shell" ] && rm "./kosaio-shell" && log_info "Removed kosaio-shell helper."
	
	log_info "Checking local state..."
	if [ -d "${HOME}/.kosaio" ]; then
		log_warn "Do you want to remove local cache/state in ${HOME}/.kosaio? (y/n)"
		read -r REMOVE_STATE
		if [[ "$REMOVE_STATE" =~ ^[Yy]$ ]]; then
			rm -rf "${HOME}/.kosaio"
			log_info "Local state removed."
		fi
	fi

	log_success "Uninstallation complete."
	exit 0
}

function configure_paths() {
	local parent_dir
	parent_dir="$(dirname "${KOSAIO_HOST_DIR}")"
	
	log_info "KOSAIO Location: ${KOSAIO_HOST_DIR}"

	PROJECTS_HOST_DIR="${PROJECTS_HOST_DIR:-}"
	if [[ -z "$PROJECTS_HOST_DIR" ]]; then
		echo -en "Enter your PROJECTS directory [${parent_dir}]: "
		read -r PROJECTS_HOST_DIR
		PROJECTS_HOST_DIR="${PROJECTS_HOST_DIR:-${parent_dir}}"
	fi

	# Ensure absolute path safely
	if [[ ! -d "$PROJECTS_HOST_DIR" ]]; then
		mkdir -p "$PROJECTS_HOST_DIR" || { log_error "Cannot create projects dir: $PROJECTS_HOST_DIR"; return 1; }
	fi
	PROJECTS_HOST_DIR="$(cd "${PROJECTS_HOST_DIR}" && pwd)"
	export PROJECTS_HOST_DIR
	log_info "Projects mapped to: ${PROJECTS_HOST_DIR}"
}

function build_image() {
	local force_rebuild="${1:-0}"
	log_info "Checking image status..."
	
	if [ "$force_rebuild" -eq 1 ] || [[ "$("${TOOL}" images -q "${IMAGE_NAME}" 2> /dev/null)" == "" ]]; then
		log_info "Building image ${IMAGE_NAME} from local Dockerfile..."
		
		# For podman, we force docker format to support labels and shell instructions better
		local build_args=()
		[[ "${TOOL}" == "podman" ]] && build_args+=("--format" "docker")
		
		"${TOOL}" build "${build_args[@]}" -t "${IMAGE_NAME}" -f "${KOSAIO_HOST_DIR}/docker/Dockerfile" "${KOSAIO_HOST_DIR}"
	else
		log_info "Image ${IMAGE_NAME} already exists. Skipping build."
	fi
}

function create_container() {
	log_info "Checking container status for '${CONTAINER_NAME}'..."
	
	if "${TOOL}" ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
		log_warn "Container '${CONTAINER_NAME}' already exists."
		echo -en "Do you want to RECREATE it? (y/n): "
		read -r REMOVE_OLD
		if [[ "$REMOVE_OLD" =~ ^[Yy]$ ]]; then
			"${TOOL}" rm -f "${CONTAINER_NAME}"
		else
			log_info "Using existing container."
			return 0
		fi
	fi

	local mount_z=""
	[[ "${TOOL}" == "podman" ]] && mount_z=":Z"

	log_info "Creating container '${CONTAINER_NAME}'..."
	
	local time_mounts=("-v" "/etc/localtime:/etc/localtime:ro")
	if [ -f "/etc/timezone" ]; then
		time_mounts+=("-v" "/etc/timezone:/etc/timezone:ro")
	fi

	"${TOOL}" run -d \
		--name "${CONTAINER_NAME}" \
		-v "${KOSAIO_HOST_DIR}:/opt/kosaio${mount_z}" \
		-v "${PROJECTS_HOST_DIR}:/opt/projects${mount_z}" \
		"${time_mounts[@]}" \
		"${IMAGE_NAME}" tail -f /dev/null
}

function create_helper_script() {
	local shell_helper="${KOSAIO_HOST_DIR}/kosaio-shell"
	
	cat <<EOF > "${shell_helper}"
#!/bin/bash
# Simple helper to enter the KOSAIO container with environment ready
${TOOL} exec -it ${CONTAINER_NAME} /bin/bash --rcfile /opt/kosaio/scripts/shell-init.sh
EOF
	chmod +x "${shell_helper}"
	
	echo ""
	log_info "KOSAIO environment is ready!"
	echo -e "You can now enter the container by running:"
	echo -e "  ${C_CYAN}./kosaio-shell${NC}"
	echo ""
}

function doctor_check() {
	log_info --draw-line "KOSAIO Host Doctor"
	local errors=0

	# 1. Container Tool
	if command -v podman >/dev/null 2>&1; then
		printf "  %-20s: ${C_GREEN}OK${NC} (podman)\n" "Container Engine"
	elif command -v docker >/dev/null 2>&1; then
		printf "  %-20s: ${C_GREEN}OK${NC} (docker)\n" "Container Engine"
	else
		printf "  %-20s: ${C_RED}FAILED${NC} (Install podman or docker)\n" "Container Engine"
		((errors++))
	fi

	# 2. Development Helpers (Optional)
	if command -v git >/dev/null 2>&1; then
		printf "  %-20s: ${C_GREEN}FOUND${NC}\n" "Host Git"
	else
		printf "  %-20s: ${C_GRAY}NOT FOUND${NC} (Optional for host-side dev)\n" "Host Git"
	fi

	# 3. Config File (Critical)
	if [ -f "$CONFIG_FILE" ]; then
		source "$CONFIG_FILE"
		printf "  %-20s: ${C_GREEN}OK${NC}\n" "Config File"
		
		if [ -n "${PROJECTS_HOST_DIR:-}" ] && [ -d "$PROJECTS_HOST_DIR" ]; then
			printf "  %-20s: ${C_GREEN}OK${NC} ($PROJECTS_HOST_DIR)\n" "Projects Path"
		else
			printf "  %-20s: ${C_YELLOW}INVALID${NC} (Check kosaio.cfg)\n" "Projects Path"
			((errors++))
		fi
	else
		printf "  %-20s: ${C_YELLOW}MISSING${NC} (Run setup to create it)\n" "Config File"
	fi

	echo ""
	if [ "$errors" -eq 0 ]; then
		log_success "Host is ready for KOSAIO!"
	else
		log_error "Host has $errors issues to resolve."
	fi
	exit $errors
}

# --- Main Execution ---

function main() {
	local action="install"
	local force_rebuild=0

	# Parse Arguments
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--install|-i)   action="install" ;;
			--uninstall|-u) action="uninstall" ;;
			--rebuild|-r)   action="install"; force_rebuild=1 ;;
			--status|-s)    action="status" ;;
			--doctor|-d)    action="doctor" ;;
			--help|-h)      show_help ;;
			*) log_error "Unknown option: $1"; show_help ;;
		esac
		shift
	done

	# Always load config and check tool for any management action
	load_config
	check_container_tool || return 1

	case "$action" in
		"install")
			configure_paths
			build_image "$force_rebuild"
			create_container
			create_helper_script
			;;
		"uninstall")
			uninstall_kosaio
			;;
		"status")
			status_check
			;;
		"doctor")
			doctor_check
			;;
	esac
}

main "$@"
