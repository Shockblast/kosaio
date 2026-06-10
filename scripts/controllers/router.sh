#!/bin/bash
# scripts/controllers/router.sh
# Central Dispatch logic for KOSAIO

# Load Controllers
source "${KOSAIO_DIR}/scripts/controllers/list.sh"
source "${KOSAIO_DIR}/scripts/controllers/dev.sh"
source "${KOSAIO_DIR}/scripts/engine/driver_refresh.sh"

function kosaio_router_dispatch() {
	local ACTION="${1:-}"
	local TARGET="${2:-}"
	local ARGS=("${@:3}") # Capture remaining filtered args

	case "$ACTION" in
		"search"|"list")
			controller_list_handle "$TARGET" "${ARGS[@]}"
			;;

		"dev-switch")
			controller_dev_handle "$TARGET" "${ARGS[0]:-}"
			;;

		"update")
			case "$TARGET" in
				self|kosaio) _router_handle_self_update ;;
				all)         _router_handle_update_all "${ARGS[@]}" ;;
				*)           _router_handle_lifecycle "$ACTION" "$TARGET" "${ARGS[@]}" ;;
			esac
			;;

		"install"|"uninstall"|"build"|"apply"|"reset"|"checkout"|"clone"|"clean"|"info"|"export") 
			_router_handle_lifecycle "$ACTION" "$TARGET" "${ARGS[@]}"
			;;

		"config")
			_router_handle_config "$TARGET" "${ARGS[0]:-}"
			;;

		"reset-config")
			_router_handle_reset_config "$TARGET"
			;;

		"apply-config")
			_router_handle_lifecycle "apply-config" "$TARGET" "${ARGS[@]}"
			;;

	"rebuild")
		_router_handle_rebuild "$TARGET"
		;;

	"refresh")
		kosaio_refresh "$TARGET"
		;;

	"diagnose")
			_router_handle_diagnose "$TARGET"
			;;

		"create-project")
			_router_handle_project "$TARGET"
			;;

		"install-deps")
			_router_handle_deps "$TARGET"
			;;

		"self-update")
			_router_handle_self_update
			;;

		"tool")
			source "${KOSAIO_DIR}/scripts/controllers/tool.sh"
			kosaio_cmd_tool "$TARGET" "${ARGS[@]}"
			;;

		*)
			show_usage 
			;;
	esac
}

# --- Internal Route Handlers ---

function _router_handle_lifecycle() {
	local action="$1"; local target="$2"; shift 2
	require_var "target" "Target is required" || show_usage

	# Validate Target
	local target_type
	if ! target_type=$(kosaio_validate_get_target_type "$target" "$action"); then
		return 1
	fi

	# Determine Handler based on validated type
	case "$target_type" in
		"port")
			case "$action" in
				"install")   ports_install "$target" "$@" ;;
				"uninstall") ports_uninstall "$target" "$@" ;;
				"update")	ports_update "$target" "$@" ;;
				"clone")	 ports_clone "$target" "$@" ;;
				"build")	 ports_build "$target" "$@" ;;
				"apply")	 ports_apply "$target" "$@" ;;
				"clean")	 ports_clean "$target" "$@" ;;
				"checkout")  ports_checkout "$target" "$@" ;;
				"reset")	 ports_reset "$target" "$@" ;;
				"info")	  ports_info "$target" "$@" ;;
				*) log_error "Action '$action' not supported for ports." ;;
			esac
			;;
		"tool"|"core"|"unknown")
			# Default to Registry Manager
			kosaio_manager_execute "$action" "$target" "$@"
			;;
		*)
			log_error "Unknown Target Type: '$target_type'"
			return 1
			;;
	esac
}

function _router_handle_diagnose() {
	local TARGET="$1"
	[ -z "$TARGET" ] && show_usage
	log_info --draw-line "Diagnosing $TARGET..."
	
	local CODE=0
	kosaio_health_check "$TARGET" || CODE=$?

	case $CODE in
		0) log_success "Target '${TARGET}' is healthy and installed." ;;
		1) log_error   "Target '${TARGET}' is NOT installed."
		   log_info    "Tip: Run 'kosaio install ${TARGET}' to set it up." ;;
		2) log_warn    "Target '${TARGET}' is incomplete or requires attention."
		   log_info    "Tip: Check the report above for MISSING/INVALID entries." ;;
		3) log_error   "System dependencies (apt) are missing for '${TARGET}'."
		   log_info    "Tip: Run 'kosaio install-deps system' or check 'provision.sh'." ;;
		4) log_error   "Target '${TARGET}' not found or manifest error." ;;
		*) log_error   "Unexpected health state for '${TARGET}'." ;;
	esac
}

function _router_handle_project() {
	local TARGET="$1"
	require_var "target" "Target is required" || show_usage
	local target_dir="/opt/projects/${target}"
	[ -d "${target_dir}" ] && { log_error "Project already exists: ${target_dir}"; exit 1; }

	log_info --draw-line "Creating project: ${TARGET}..."
	mkdir -p "${target_dir}"
	cp -rv "${KOSAIO_DIR}/basic-project/." "${target_dir}/" > /dev/null
	chown -R --reference=/opt/projects "${target_dir}"
	log_success "Project created at ${target_dir}."
}

function _router_handle_config() {
	local target="$1"
	local mode="${2:-}"
	require_var "target" "Target is required" || show_usage

	# --meta flag opens the .tool file (metadata)
	if [ "$mode" = "--meta" ]; then
		local tool_path="${KOSAIO_DIR}/scripts/registry/tools/${target}.tool"
		if [ ! -f "$tool_path" ]; then
			log_error "Metadata not found for '${target}'."
			return 1
		fi
		${EDITOR:-nano} "$tool_path"
		return $?
	fi

	# Default: open .cfg (build configuration)
	local cfg_path="${KOSAIO_DIR}/data/cfg/${target}.cfg"
	local cfg_default="${KOSAIO_DIR}/scripts/registry/cfg/${target}.cfg.default"

	if [ ! -f "$cfg_default" ]; then
		log_info "No build configuration available for '${target}'."
		log_info "Use 'kosaio config ${target} --meta' to edit metadata."
		return 0
	fi

	if [ ! -f "$cfg_path" ]; then
		cp "$cfg_default" "$cfg_path"
		log_success "Created personal config from default template."
	fi

	${EDITOR:-nano} "$cfg_path"
}

function _router_handle_reset_config() {
	local target="$1"
	require_var "target" "Target is required" || show_usage

	local cfg_path="${KOSAIO_DIR}/data/cfg/${target}.cfg"
	local cfg_default="${KOSAIO_DIR}/scripts/registry/cfg/${target}.cfg.default"

	if [ ! -f "$cfg_default" ]; then
		log_error "No default configuration exists for '${target}'. Cannot reset."
		return 1
	fi

	cp "$cfg_default" "$cfg_path"
	log_success "Reset '${target}' configuration to defaults."
	${EDITOR:-nano} "$cfg_path"
}

function _router_handle_rebuild() {
	local target="$1"
	require_var "target" "Target is required" || show_usage
	export KOSAIO_NON_INTERACTIVE=1
	_router_handle_lifecycle "uninstall" "$target" || true
	_router_handle_lifecycle "install" "$target"
	unset KOSAIO_NON_INTERACTIVE
}

function _router_handle_deps() {
	local TARGET="$1"
	if [ "$TARGET" == "system" ]; then
		kosaio_install_core_sdk_deps
	else
		log_error "install-deps only supports 'system' target. Use 'install <id>' for tools."
		return 1
	fi
}

function _router_handle_self_update() {
	log_info --draw-line "Updating KOSAIO..."
	kosaio_git_fix_permissions
	kosaio_git_common_update "${KOSAIO_DIR}" --branch "${KOSAIO_BRANCH}"
}

function _router_handle_update_all() {
	log_info --draw-line "Updating all installed tools and ports..."
	
	# Get list of installed IDs from Python engine
	local installed_ids
	installed_ids=$(python3 "${KOSAIO_DIR}/scripts/engine/py/main.py" get_installed_ids) || {
		log_error "Failed to retrieve installed targets."
		return 1
	}

	if [ -z "$installed_ids" ]; then
		log_warn "No installed targets found to update."
		return 0
	fi

	# Force non-interactive mode for bulk update
	export KOSAIO_NON_INTERACTIVE=1
	export KOSAIO_BULK_UPDATE=1
	
	local results=()

	for id in $installed_ids; do
		log_info "Updating: $id"
		local status=0
		_router_handle_lifecycle "update" "$id" "$@" || status=$?
		results+=("${id}:${status}")
	done
	
	# Restore interactive mode
	unset KOSAIO_NON_INTERACTIVE
	unset KOSAIO_BULK_UPDATE
	
	echo ""
	log_info --draw-line "BULK UPDATE SUMMARY"
	
	local count_uptodate=0
	local count_updated=0
	local count_skipped=0
	local count_error=0

	for res in "${results[@]}"; do
		local id="${res%%:*}"
		local code="${res#*:}"
		local log_file="/tmp/kosaio_update_${id}.log"
		
		case $code in
			10) 
				printf "  ${C_GRAY}[UP-TO-DATE]${C_RESET}  %-15s %s\n" "$id" "No changes found."
				((count_uptodate++))
				;;
			11)
				printf "  ${C_B_CYAN}[UPDATED]   ${C_RESET}  %-15s ${C_GREEN}%s${C_RESET}\n" "$id" "Rebuilt & Deployed"
				# Print changelog if it exists
				if [ -f "$log_file" ]; then
					while read -r line; do
						printf "                    ${C_GRAY}* %s${C_RESET}\n" "$line"
					done < "$log_file" # Show all commits
				fi
				((count_updated++))
				;;
			12)
				printf "  ${C_YELLOW}[SKIPPED]   ${C_RESET}  %-15s %s\n" "$id" "Code updated, build skipped."
				((count_skipped++))
				;;
			0)
				# Handle targets that don't return our special codes yet but succeeded
				printf "  ${C_GRAY}[SUCCESS]   ${C_RESET}  %-15s %s\n" "$id" "Completed."
				((count_uptodate++))
				;;
			*)
				printf "  ${C_RED}[ERROR]     ${C_RESET}  %-15s %s\n" "$id" "Failed with code $code"
				((count_error++))
				;;
		esac
		rm -f "$log_file"
	done

	echo ""
	log_info "Summary: ${C_B_CYAN}$count_updated${C_RESET} updated, ${C_GRAY}$count_uptodate${C_RESET} up-to-date, ${C_RED}$count_error${C_RESET} failed."
	
	if [ $count_error -eq 0 ]; then
		log_success "Bulk update complete."
	else
		log_error "Bulk update finished with some errors."
	fi
}
