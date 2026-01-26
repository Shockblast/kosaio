set -Eeuo pipefail
# driver_search.sh - Integration driver for Search Engine
# This is a library of functions, not intended for direct execution.

function search_execute() {
	# Ensure search utils are loaded
	source "${KOSAIO_DIR}/scripts/common/search_utils.sh"

	# Pass all arguments to the unified engine wrapper
	kosaio_search_engine "$@"
}
