# error_handler.sh - Contextual Error Suggestions

# Suggests fixes based on the last command or error context
function kosaio_suggest_fix() {
	local last_cmd="$1"
	local exit_code="$2"

	log_info --draw-line "${C_BOLD}Suggestion:${C_RESET}"

	if [[ "$last_cmd" == *"make install"* ]]; then
		echo -e "  It seems the installation failed. Try running with ${C_YELLOW}--reinstall${C_RESET} to clean up first."
	elif [[ "$last_cmd" == *"fetch"* ]]; then
		echo -e "  Network error? Check your internet connection or git configuration."
	elif [[ "$exit_code" -eq 127 ]]; then
		echo -e "  Command not found. Maybe you are missing a system dependency?"
	else
		echo -e "  Check the logs above for details."
	fi

}

# Optional: Global Trap (Use with caution in legacy scripts)
function kosaio_enable_strict_mode() {
	set -e
	trap 'log_error "Command failed at line $LINENO"; kosaio_suggest_fix "$BASH_COMMAND" "$?"' ERR
}
