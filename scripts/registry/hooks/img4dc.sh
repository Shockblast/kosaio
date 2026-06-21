#!/bin/bash
# scripts/registry/hooks/img4dc.sh
# Tool hooks for img4dc: multi-location binary discovery in apply + export
# Loaded automatically by helper_loader.sh

kosaio_tool_info() {
	local tool_dir=$(__get_tool_dir)
	local build_dir="${tool_dir}/build"
	local status="${C_RED}Not Compiled${C_RESET}"
	[ -f "${build_dir}/cdi4dc/cdi4dc" ] || [ -f "${build_dir}/cdi4dc" ] && status="${C_GREEN}Compiled${C_RESET}"

	log_box --info "img4dc: DISC IMAGE TOOLS" \
		"${C_YELLOW}Context:${C_RESET} Generates Dreamcast disc images (CDI/GDI/MDS)." \
		"${C_YELLOW}Status:${C_RESET}  ${status}" \
		"${C_YELLOW}Source:${C_RESET}  ${tool_dir}" \
		"${C_YELLOW}Tools:${C_RESET}   cdi4dc, gdi4dc, mds4dc" \
		"${C_YELLOW}Install:${C_RESET} Binaries go to ${C_CYAN}${KOSAIO_BIN_PATH}${C_RESET}"
}

kosaio_tool_check_health() {
	local tool_dir=$(__get_tool_dir)
	local build_dir="${tool_dir}/build"
	local bin_path="${KOSAIO_BIN_PATH}"

	if [ ! -d "$tool_dir" ]; then
		log_box --info "img4dc — Health Check" \
			"${C_YELLOW}Status:${C_RESET} ${C_RED}Not Installed${C_RESET}" \
			"" \
			"${C_RED}✗${C_RESET} Source missing at ${tool_dir}"
		return 1
	fi

	local compiled=0
	[ -f "${build_dir}/cdi4dc/cdi4dc" ] || [ -f "${build_dir}/cdi4dc" ] && compiled=1

	if [ "$compiled" -eq 0 ]; then
		log_box --info "img4dc — Health Check" \
			"${C_YELLOW}Status:${C_RESET} ${C_YELLOW}Not Compiled${C_RESET}" \
			"" \
			"${C_GREEN}✓${C_RESET} Source: ${tool_dir}" \
			"${C_RED}✗${C_RESET} Binary: not built"
		return 2
	fi

	local installed=0
	[ -f "${bin_path}/cdi4dc" ] && installed=1

	if [ "$installed" -eq 0 ]; then
		log_box --info "img4dc — Health Check" \
			"${C_YELLOW}Status:${C_RESET} ${C_YELLOW}Built, Not Applied${C_RESET}" \
			"" \
			"${C_GREEN}✓${C_RESET} Source: ${tool_dir}" \
			"${C_GREEN}✓${C_RESET} Binary: built" \
			"${C_RED}✗${C_RESET} Applied: not in ${bin_path}"
		return 2
	fi

	log_box --info "img4dc — Health Check" \
		"${C_YELLOW}Status:${C_RESET} ${C_GREEN}Healthy${C_RESET}" \
		"" \
		"${C_GREEN}✓${C_RESET} Source: ${tool_dir}" \
		"${C_GREEN}✓${C_RESET} Binary: built" \
		"${C_GREEN}✓${C_RESET} Applied: ${bin_path}/cdi4dc"
	return 0
}

kosaio_tool_apply() {
	local tool_dir=$(__get_tool_dir)
	local build_dir="${tool_dir}/build"

	mkdir -p "${KOSAIO_BIN_PATH}"

	if [ -f "${build_dir}/cdi4dc/cdi4dc" ]; then
		cp "${build_dir}/cdi4dc/cdi4dc" "${KOSAIO_BIN_PATH}/"
		[ -f "${build_dir}/gdi4dc/gdi4dc" ] && cp "${build_dir}/gdi4dc/gdi4dc" "${KOSAIO_BIN_PATH}/"
	elif [ -f "${build_dir}/cdi4dc" ]; then
		cp "${build_dir}/cdi4dc" "${KOSAIO_BIN_PATH}/"
	fi

	log_success "img4dc binaries installed to ${KOSAIO_BIN_PATH}"
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
			count=$((count + 1))
		fi
	done

	if [ $count -eq 0 ] && [ -f "${build_dir}/cdi4dc" ]; then
		cp -v "${build_dir}/cdi4dc" "${host_out}/"
		count=$((count + 1))
	fi

	if [ $count -eq 0 ]; then
		log_error "No binaries found to export. Run 'kosaio build ${ID}' first."
		return 1
	fi

	log_success "Export complete. ${count} binaries exported to ${host_out}/"
}
