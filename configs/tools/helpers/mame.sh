#!/bin/bash
# configs/tools/helpers/mame.sh
# Prebuild arg translator for MAME: RAM-aware thread throttling + make flags
# Loaded automatically by helper_loader.sh when using kosaio * mame

function kosaio_translate_mame_args() {
	local use_full_power=0
	local use_debug=0

	for arg in "$@"; do
		[[ "$arg" == "--full-power" ]] && use_full_power=1
		[[ "$arg" == "--debug" ]] && use_debug=1
	done

	local total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
	local total_ram_gb=$(( total_ram_kb / 1024 / 1024 ))
	local cpu_cores=$(nproc)
	local build_jobs=1

	if [ "$use_full_power" -eq 1 ]; then
		build_jobs=$cpu_cores
	else
		local safe_jobs=$(( total_ram_gb * 10 / 25 ))
		[ "$safe_jobs" -lt 1 ] && safe_jobs=1
		[ "$safe_jobs" -gt "$cpu_cores" ] && build_jobs=$cpu_cores || build_jobs=$safe_jobs
	fi

	local symbols_val=0
	[ "$use_debug" -eq 1 ] && symbols_val=1

	if [ -z "${KOSAIO_NON_INTERACTIVE:-}" ] && [ "$use_full_power" -eq 0 ]; then
		confirm "Proceed with compilation using ${build_jobs} threads?" || return 1
	fi

	KOSAIO_TRANSLATED_ARGS=(
		"-j${build_jobs}"
		"SUBTARGET=mame"
		"SOURCES=src/mame/sega/dccons.cpp"
		"SYMBOLS=${symbols_val}"
		"REGENIE=1"
	)
}
