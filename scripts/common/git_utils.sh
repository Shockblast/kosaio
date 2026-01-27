#!/bin/bash
set -Eeuo pipefail
# scripts/common/git_utils.sh
# Shared Git utility functions for KOSAIO and related tools.

function kosaio_git_common_update() {
	local repo_dir="$1"
	shift
	local force_update=0

	local target_branch=""
	# Simple flag parsing
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--force) force_update=1 ;;
			--branch) shift; target_branch="$1" ;;
			*) ;; # Ignore other args
		esac
		shift
	done

	if [[ -z "${repo_dir}" ]]; then
		log_info --draw-line "Usage: kosaio_git_common_update <path_to_repo> [--force]" >&2
		return 1
	fi

	if [[ -d "${repo_dir}" ]]; then
		cd "${repo_dir}" || return 1
		log_info --draw-line "Checking updates in $(basename "${repo_dir}")..."

		# Safety Check: Abort if dirty unless forced
		if ! git diff-index --quiet HEAD --; then
			if [ "$force_update" -eq 1 ]; then
				log_warn "Local changes detected. Overwriting due to --force."
				git reset --hard HEAD
			else
				log_error "Local changes detected in $(basename "${repo_dir}")."
				log_info "To overwrite your changes and update, use: ${C_YELLOW}--force${C_RESET}"
				return 2
			fi
		fi

		local old_head=$(git rev-parse HEAD)
		local current_branch=$(git rev-parse --abbrev-ref HEAD)
		local branch_to_update="${target_branch:-$current_branch}"

		log_info "Fetching ${branch_to_update} from origin..."
		git fetch origin "${branch_to_update}" --depth=1 || return 2

		local upstream="origin/${branch_to_update}"
		local local_rev=$(git rev-parse HEAD)
		local remote_rev=$(git rev-parse "${upstream}" 2>/dev/null)

		if [[ -z "$remote_rev" ]]; then
			log_warn "Target branch '${branch_to_update}' not found on remote. Skipping."
			return 0
		fi

		local base_rev=$(git merge-base HEAD "${upstream}")

		if [[ "${local_rev}" == "${remote_rev}" ]]; then
			log_success "Code is already up-to-date."
			return 0
		elif [[ "${local_rev}" == "${base_rev}" ]]; then
			git reset --hard
			log_info "Local branch is behind '${upstream}'. Pulling changes..."
			git pull || return 2
			log_info "New changes:"
			git log --pretty=format:'%h - %s (%cr)' "${old_head}..HEAD"
			return 1
		elif [[ "${remote_rev}" == "${base_rev}" ]]; then
			log_success "Local branch is ahead of '${upstream}'. Nothing to pull."
			return 0
		else
			git reset --hard
			log_warn "Branches have diverged. Resetting to remote '${upstream}'..."
			git pull || return 2
			log_info "New changes:"
			git log --pretty=format:'%h - %s (%cr)' "${old_head}..HEAD"
			return 1
		fi
	fi
}

# --- High Level Lifecycle Helpers ---

function kosaio_standard_update_flow() {
	local id="$1"
	local name="$2"
	local repo_dir="$3"
	local build_cmd="${4:-}"
	local apply_cmd="${5:-}"
	# Note: any additional parameters via "$@" are passed to the build/apply commands
	shift 5 || shift 3 # Handle 3 or 5 positional args
	local status=0

	kosaio_git_common_update "${repo_dir}" || status=$?

	if [ $status -eq 1 ]; then
		# Try to update submodules if any
		if [ -f "${repo_dir}/.gitmodules" ]; then
			log_info "Updating submodules..."
			(cd "${repo_dir}" && git submodule update --init --recursive 2>/dev/null || true)
		fi

		if confirm "New changes detected in ${name}. Do you want to rebuild and apply?" "Y"; then
			# Case A: Custom commands provided
			if [ -n "$build_cmd" ]; then
				$build_cmd "$@"
				[ -n "$apply_cmd" ] && $apply_cmd "$@"
			# Case B: Standard Registry functions
			else
				if [ "$(type -t reg_build)" == "function" ]; then
					reg_build "$@"
				fi
				if [ "$(type -t reg_apply)" == "function" ]; then
					reg_apply "$@"
				fi
			fi
		else
			log_info "Skipping build for ${name}."
		fi
	elif [ $status -eq 0 ]; then
		log_info "${name} is already up-to-date."
	fi
}

function kosaio_git_clone() {
	# Parse arguments
	local target=""
	local is_recursive=0
	local args_copy=("$@")

	# First pass: find flags and target
	for arg in "${args_copy[@]}"; do
		if [[ "$arg" == "--recursive" ]]; then
			is_recursive=1
		elif [[ "$arg" != -* ]]; then
			target="$arg"
		fi
	done

	local full_clone=0
	if [ "${KOSAIO_DEV_MODE:-}" == "1" ]; then
		full_clone=1
	elif [[ -n "$target" ]] && [[ "$target" == "${KOSAIO_DEV_ROOT:-}"* ]]; then
		full_clone=1
	elif [ "$is_recursive" -eq 1 ]; then
		# Submodules often fail with --depth=1
		full_clone=1
	fi

	if [ "$full_clone" -eq 1 ]; then
		log_info "Performing full clone..."
		git clone "$@"
	else
		log_info "Performing shallow clone..."
		git clone --depth=1 --single-branch "$@"
	fi
}

function kosaio_git_checkout() {
	local repo_dir="$1"
	local ref="$2"
	local hard_reset="${3:-true}" # Default to hard reset for sdk-like behavior

	if [[ -z "${repo_dir}" ]] || [[ -z "${ref}" ]]; then
		log_error "Usage: kosaio_git_checkout <repo_dir> <ref> [hard_reset_bool]"
		return 1
	fi

	if [ ! -d "${repo_dir}/.git" ]; then
		log_error "'${repo_dir}' is not a valid git repository."
		return 1
	fi

	cd "${repo_dir}" || return 1

	log_info "Switching $(basename "${repo_dir}") to: ${ref}"

	# If it's a hard reset, we clean everything first
	if [ "${hard_reset}" = "true" ]; then
		git fetch --all --tags || true
		if git reset --hard "${ref}"; then
			log_success "Successfully reset to ${ref}"
			return 0
		else
			log_error "Failed to reset to ${ref}"
			return 1
		fi
	else
		if git checkout "${ref}"; then
			log_success "Successfully checked out ${ref}"
			return 0
		else
			log_error "Failed to checkout ${ref}"
			return 1
		fi
	fi
}

function kosaio_git_fix_permissions() {
	log_info "Applying global git safe.directory fix..."
	git config --global --add safe.directory '*'
	log_success "Git safe directory check disabled for all paths."
}
