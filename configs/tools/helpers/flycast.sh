#!/bin/bash
# configs/tools/helpers/flycast.sh
# Prebuild arg translator for Flycast: --with-gdb, --debug, --release
# Loaded automatically by helper_loader.sh

KOSAIO_TRANSLATED_ARGS=()

function kosaio_translate_flycast_args() {
	KOSAIO_TRANSLATED_ARGS=()
	local build_system="${1:?}"
	shift

	local gdb_state="OFF"
	local build_type="Release"

	for arg in "$@"; do
		case "$arg" in
			--with-gdb)
				gdb_state="ON"
				;;
			--debug)
				build_type="Debug"
				;;
			--release)
				build_type="Release"
				;;
			*)
				KOSAIO_TRANSLATED_ARGS+=("$arg")
				;;
		esac
	done

	KOSAIO_TRANSLATED_ARGS=(
		"-DENABLE_GDB_SERVER=${gdb_state}"
		"-DCMAKE_BUILD_TYPE=${build_type}"
	)
}
