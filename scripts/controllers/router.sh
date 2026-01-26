#!/bin/bash
# scripts/controllers/router.sh
# Central Dispatch logic for KOSAIO

# Load Controllers
source "${KOSAIO_DIR}/scripts/controllers/list.sh"
source "${KOSAIO_DIR}/scripts/controllers/dev.sh"

function kosaio_router_dispatch() {
	local ACTION="${1:-}"
	local TARGET="${2:-}"
	local ARGS=("${@:3}") # Capture remaining args

	case "$ACTION" in
		"search"|"list")
			controller_list_handle "$TARGET" "${ARGS[@]}"
			;;

		"dev-switch")
			controller_dev_handle "$TARGET" "${ARGS[0]:-}"
			;;

		"install"|"update"|"uninstall"|"build"|"apply"|"reset"|"checkout"|"clone"|"clean"|"info") 
			_router_handle_lifecycle "$ACTION" "$TARGET" "${ARGS[@]}"
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
	if ! target_type=$(validate_get_target_type "$target" "$action"); then
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
			manager_execute "$action" "$target" "$@"
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
	health_check "$TARGET" || CODE=$?

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
