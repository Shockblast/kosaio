# --- Color Palette ---
# Using raw ESC characters for reliable printing
ESC=$'\e'
C_RESET="${ESC}[0m"
C_BOLD="${ESC}[1m"
C_CYAN="${ESC}[0;36m"
C_B_CYAN="${ESC}[1;36m"
C_BLUE="${ESC}[1;34m"
C_GREEN="${ESC}[1;32m"
C_YELLOW="${ESC}[1;33m"
C_RED="${ESC}[1;31m"
C_GRAY="${ESC}[0;90m"

# --- Logging Functions ---

function _get_timestamp() {
	case "${KOSAIO_LOG_MODE:-FULL}" in
		"FULL") date +'%Y-%m-%d %H:%M:%S' ;;
		"SHORT") date +'%H:%M:%S' ;;
		*) echo "" ;;
	esac
}

function _log_msg() {
	local level="$1"
	local color="$2"
	local msg="$3"
	local ts=$(_get_timestamp)

	if [ -n "$ts" ]; then
		printf "%s[%s] %s:%s %s\n" "${color}" "${ts}" "${level}" "${C_RESET}" "${msg}" >&2
	else
		printf "%s%s:%s %s\n" "${color}" "${level}" "${C_RESET}" "${msg}" >&2
	fi
}

function log_info() {
	if [[ "${1:-}" == "--draw-line" ]]; then
		printf "%s----------------------------------------%s\n" "${C_B_CYAN}" "${C_RESET}" >&2
		shift
		_log_msg "INFO" "${C_CYAN}" "$*"
		printf "\n" >&2
	else
		_log_msg "INFO" "${C_CYAN}" "$*"
	fi
}

function log_warn() {
	_log_msg "WARN" "${C_YELLOW}" "$*"
}

function log_error() {
	_log_msg "ERROR" "${C_RED}" "$*"
}

function log_success() {
	_log_msg "SUCCESS" "${C_GREEN}" "$*"
}

function log_debug() {
	if [[ "${DEBUG:-0}" == "1" ]]; then
		_log_msg "DEBUG" "${C_GRAY}" "$*"
	fi
}
