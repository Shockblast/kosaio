#!/bin/bash
# scripts/registry/hooks/deecy.sh
# Build hook + health check for Deecy emulator.
# Handles per-version Zig download from .zigversion.
# Loaded automatically by helper_loader.sh

KOSAIO_ZIG_DIR="${KOSAIO_DIR}/data/lib/zig"

kosaio_tool_build() {
	local tool_dir=$(__get_tool_dir)
	[ -d "$tool_dir" ] || { log_error "Deecy source missing. Run 'kosaio clone deecy' first."; return 1; }

	# Read required Zig version from repo's .zigversion
	local zig_version
	zig_version=$(cat "$tool_dir/.zigversion" 2>/dev/null || echo "0.16.0")
	log_info "Deecy requires Zig ${zig_version}"

	# Ensure we have the exact version
	local zig_bin
	zig_bin=$(_ensure_zig "$zig_version") || return 1

	# Apply config (reads .cfg if present)
	kosaio_reg_apply_config "$@"

	cd "$tool_dir"
	log_info "Building Deecy with Zig ${zig_version}..."
	"$zig_bin" build --release=fast "${KOSAIO_TOOL_ARGS[@]}"
}

kosaio_tool_info() {
	local tool_dir=$(__get_tool_dir)
	local binary="${tool_dir}/zig-out/bin/Deecy"
	local status="${C_RED}Not Compiled${C_RESET}"
	[ -f "$binary" ] && status="${C_GREEN}Compiled${C_RESET}"

	local required_zig="?"
	[ -f "$tool_dir/.zigversion" ] && required_zig=$(cat "$tool_dir/.zigversion")
	local installed_zig=$(_installed_zig_version "$required_zig")

	log_box --info "DEECY: DREAMCAST EMULATOR (ZIG)" \
		"${C_YELLOW}Status:${C_RESET}  ${status}" \
		"${C_YELLOW}Source:${C_RESET}  ${tool_dir}" \
		"${C_YELLOW}Zig:${C_RESET}     ${required_zig} (${installed_zig})" \
		"${C_YELLOW}BIOS:${C_RESET}    Needs dc_boot.bin + dc_flash.bin"
}

kosaio_tool_check_health() {
	local tool_dir=$(__get_tool_dir)
	local binary="${tool_dir}/zig-out/bin/Deecy"

	if [ ! -d "$tool_dir" ]; then
		log_box --info "Deecy — Health Check" \
			"${C_YELLOW}Status:${C_RESET} ${C_RED}Not Installed${C_RESET}" \
			"" \
			"${C_RED}✗${C_RESET} Source missing at ${tool_dir}"
		return 1
	fi

	if [ ! -f "$binary" ]; then
		log_box --info "Deecy — Health Check" \
			"${C_YELLOW}Status:${C_RESET} ${C_YELLOW}Not Compiled${C_RESET}" \
			"" \
			"${C_GREEN}✓${C_RESET} Source: ${tool_dir}" \
			"${C_RED}✗${C_RESET} Binary: ${binary}"
		return 2
	fi

	log_box --info "Deecy — Health Check" \
		"${C_YELLOW}Status:${C_RESET} ${C_GREEN}Healthy${C_RESET}" \
		"" \
		"${C_GREEN}✓${C_RESET} Source: ${tool_dir}" \
		"${C_GREEN}✓${C_RESET} Binary: ${binary}"
	return 0
}

# ── helpers ──────────────────────────────────────────

_installed_zig_version() {
	local ver="${1:-}"
	[ -z "$ver" ] && echo "not checked" && return
	[ -f "${KOSAIO_ZIG_DIR}/${ver}/zig" ] && echo "installed" || echo "not installed"
}

_ensure_zig() {
	local version="$1"
	local install_dir="${KOSAIO_ZIG_DIR}/${version}"
	local zig_bin="${install_dir}/zig"

	[ -f "$zig_bin" ] && { echo "$zig_bin"; return 0; }

	log_info "Downloading Zig ${version}..."
	mkdir -p "$KOSAIO_ZIG_DIR"

	local tarball=""
	local url=""
	for pattern in \
		"zig-x86_64-linux-${version}" \
		"zig-linux-x86_64-${version}"; do
		for base in \
			"https://ziglang.org/download/${version}" \
			"https://ziglang.org/builds"; do
			url="${base}/${pattern}.tar.xz"
			if wget --spider -q "$url" 2>/dev/null; then
				tarball="${pattern}.tar.xz"
				break 2
			fi
		done
	done

	if [ -z "$tarball" ]; then
		log_error "No Zig build found for version ${version}"
		log_info "Check https://ziglang.org/download/ for available versions."
		return 1
	fi

	wget -q "$url" -O "/tmp/${tarball}"
	tar -xf "/tmp/${tarball}" -C "$KOSAIO_ZIG_DIR"

	# Detect extracted dir (name may differ from tarball, e.g. zig-x86_64-linux-x.y.z → zig-linux-x86_64-x.y.z)
	local extracted
	extracted=$(tar -tf "/tmp/${tarball}" 2>/dev/null | head -1 | cut -d/ -f1)
	if [ -n "$extracted" ]; then
		[ -d "$install_dir" ] && rm -rf "$install_dir"
		[ "$extracted" != "$(basename "$install_dir")" ] && mv "${KOSAIO_ZIG_DIR}/${extracted}" "$install_dir"
	fi
	rm -f "/tmp/${tarball}"

	[ -f "$zig_bin" ] && { log_success "Zig ${version} installed at ${install_dir}"; echo "$zig_bin"; return 0; }
	log_error "Failed to install Zig ${version}"
	return 1
}
