# scripts/common/search_utils.sh
# Main search engine wrapper. Calls Python Engine for all logic.

# Format: ID | NAME | DESC | TAGS | TYPE | MANIFEST_PATH
function kosaio_search_engine() {
	local python_engine="${KOSAIO_DIR}/scripts/engine/py/main.py"

	if [ -f "$python_engine" ] && command -v python3 >/dev/null 2>&1; then
		# Pass all arguments naturally (query and flags)
		python3 "$python_engine" search "$@"
	else
		log_error "Python search engine not found or python3 missing."
		return 1
	fi
}

