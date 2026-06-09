#!/bin/bash
# configs/tools/helpers/img4dc.sh
# Tool hooks for img4dc: multi-location binary discovery in apply + export
# Loaded automatically by helper_loader.sh

kosaio_tool_apply() {
	local tool_dir=$(__get_tool_dir)
	local build_dir="${tool_dir}/build"

	mkdir -p "${DREAMCAST_BIN_PATH}"

	if [ -f "${build_dir}/cdi4dc/cdi4dc" ]; then
		cp "${build_dir}/cdi4dc/cdi4dc" "${DREAMCAST_BIN_PATH}/"
		[ -f "${build_dir}/gdi4dc/gdi4dc" ] && cp "${build_dir}/gdi4dc/gdi4dc" "${DREAMCAST_BIN_PATH}/"
	elif [ -f "${build_dir}/cdi4dc" ]; then
		cp "${build_dir}/cdi4dc" "${DREAMCAST_BIN_PATH}/"
	fi

	log_success "img4dc binaries installed to ${DREAMCAST_BIN_PATH}"
}

kosaio_tool_export() {
	local tool_dir=$(__get_tool_dir)
	local host_out="${KOSAIO_DIR}/out/${ID}"
	local build_dir="${tool_dir}/build"

	log_info "Exporting ${NAME} artifacts to host..."

	mkdir -p "${host_out}"
	local count=0

	for bin in "cdi4dc/cdi4dc" "gdi4dc/gdi4dc" "mds4dc/mds4dc"; do
		if [ -f "${build_dir}/${bin}" ]; then
			cp -v "${build_dir}/${bin}" "${host_out}/"
			((count++))
		fi
	done

	if [ $count -eq 0 ] && [ -f "${build_dir}/cdi4dc" ]; then
		cp -v "${build_dir}/cdi4dc" "${host_out}/"
		((count++))
	fi

	if [ $count -eq 0 ]; then
		log_error "No binaries found to export. Run 'kosaio build ${ID}' first."
		return 1
	fi

	log_success "Export complete. ${count} binaries exported to ${host_out}/"
}
