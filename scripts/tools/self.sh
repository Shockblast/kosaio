#!/bin/bash
set -e

function info() {
	kosaio_echo "KOSAIO Self-Management Tool"
	echo "This tool manages the health and configuration of KOSAIO itself."
}

function fix-git() {
	kosaio_echo "Standardizing KOSAIO Git configurations..."
	git config --global pull.rebase true
	git config --global core.fileMode false
	kosaio_echo "GIT CONFIG FIXED"
}

function diagnose() {
	kosaio_echo "Starting KOSAIO Self-Diagnosis..."
	local errors=0
	local warnings=0

	# 1. Directory Checks
	echo "--- Structure Check ---"
	if [ -d "${KOSAIO_DIR}/scripts" ]; then
		kosaio_print_status "PASS" "KOSAIO structure is valid."
	else
		kosaio_print_status "FAIL" "KOSAIO scripts directory not found!"
		((errors++))
	fi

	# 2. Permissions
	echo -e "\n--- Permissions Check ---"
	if [ -w "${KOSAIO_DIR}" ]; then
		kosaio_print_status "PASS" "KOSAIO directory is writable."
	else
		kosaio_print_status "WARN" "KOSAIO directory is not writable by current user."
		((warnings++))
	fi

	# 3. Update Status
	echo -e "\n--- Update Status ---"
	if [ -d "${KOSAIO_DIR}/.git" ]; then
		cd "${KOSAIO_DIR}"
		git fetch origin >/dev/null 2>&1
		local upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
		if [ -n "$upstream" ]; then
			local local_rev=$(git rev-parse @)
			local remote_rev=$(git rev-parse @{u})
			if [ "$local_rev" != "$remote_rev" ]; then
				kosaio_print_status "WARN" "KOSAIO is out of date. Run 'kosaio self-update' to update."
				((warnings++))
			else
				kosaio_print_status "PASS" "KOSAIO is up to date."
			fi
		else
			kosaio_print_status "WARN" "No upstream branch found. Cannot check for updates."
			((warnings++))
		fi
	else
		kosaio_print_status "WARN" "KOSAIO is not a git repository."
		((warnings++))
	fi

	echo -e "\n========================================"
	echo "Self-Diagnosis Complete: $errors Errors, $warnings Warnings."
	if [ "$errors" -ne 0 ]; then
		exit 1
	else
		exit 0
	fi
}
