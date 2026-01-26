#!/bin/bash
# common/errors.sh - Standardized error handling helpers
# Depends on: common/ui.sh (for logging)

# Core error function: Log error and exit
function die() {
	log_error "$1"
	exit "${2:-1}"
}

# Assertions
function check_dir() {
	local dir="$1"
	local msg="${2:-Directory not found: $dir}"
	[ -d "$dir" ] || die "$msg"
}

function check_file() {
	local file="$1"
	local msg="${2:-File not found: $file}"
	[ -f "$file" ] || die "$msg"
}

function require_cmd() {
	local cmd="$1"
	command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
}

function require_var() {
	local var_name="$1"
	local var_value="${!var_name:-}"
	[ -n "$var_value" ] || die "Required variable not set: $var_name"
}

# Non-fatal checkers (returns 1 instead of exit)
function check_dir_soft() {
	local dir="$1"
	local msg="${2:-Directory not found: $dir}"
	if [ ! -d "$dir" ]; then
		log_error "$msg"
		return 1
	fi
	return 0
}

function check_file_soft() {
	local file="$1"
	local msg="${2:-File not found: $file}"
	if [ ! -f "$file" ]; then
		log_error "$msg"
		return 1
	fi
	return 0
}
