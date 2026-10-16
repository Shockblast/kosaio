#!/bin/bash
# scripts/registry/hooks/nulldc3.sh
# Build hook + health check for nullDC 3 emulator.
# Two-step build: (1) Dreamcast DevTools web UI via npm, embedded into the
# binary by CMake; (2) emulator via CMake + Ninja.
# Loaded automatically by helper_loader.sh

KOSAIO_NULLDC3_MIN_NODE_MAJOR=22
KOSAIO_NULLDC3_MIN_NODE_MINOR=13

kosaio_tool_clone() {
	local tool_dir
	tool_dir=$(__get_tool_dir)

	if [ -z "${KOSAIO_TOOL_REPO:-}" ]; then
		log_error "No repository configured for nullDC 3."
		return 1
	fi

	# Shallow clone would break submodule pin comparison; devtools-only init
	# avoids pulling the ~90MB test vectors under tests/vendor/.
	if [ -d "$tool_dir" ]; then
		log_warn "Directory already exists: ${tool_dir}"
		return 0
	fi

	log_info --draw-line "Cloning nullDC 3..."
	log_info "Branch: ${C_YELLOW}${KOSAIO_TOOL_BRANCH:-default}${C_RESET}"
	log_info "Target: ${tool_dir}"

	kosaio_git_clone --branch "${KOSAIO_TOOL_BRANCH}" "${KOSAIO_TOOL_REPO}" "${tool_dir}" || return 1
	kosaio_git_exclude_dir "${tool_dir}" 2>/dev/null || true

	_nulldc3_submodule_devtools "$tool_dir" || return 1
}

kosaio_tool_install() {
	kosaio_reg_clone || return 1
	kosaio_reg_build "$@" || return 1
	kosaio_reg_apply "$@" || return 1

	kosaio_state_set container "$ID"

	log_box --success "NULLDC3 INSTALLED — DEV QUICKSTART" \
		"${C_YELLOW}Run ELF:${C_RESET} ./build/nulldc3 game.elf (no BIOS needed, reios)" \
		"${C_YELLOW}Headless:${C_RESET} --config config:Headless=yes , audio:backend=none ," \
		"  config:Exit.AfterVblanks=600 , config:Exit.StateHash=yes game.elf" \
		"${C_YELLOW}Debugger:${C_RESET} http://127.0.0.1:55543/ while running" \
		"${C_YELLOW}Discs:${C_RESET} dc_boot.bin + dc_flash.bin go in data/"
	log_success "nullDC 3 installation complete."
}

kosaio_tool_build() {
	local tool_dir
	tool_dir=$(__get_tool_dir)
	[ -d "$tool_dir" ] || { log_error "nullDC 3 source missing. Run 'kosaio clone nulldc3' first."; return 1; }

	local skip_ui=0
	local explicit_dist=""
	for arg in "$@"; do
		case "$arg" in
			--no-ui) skip_ui=1 ;;
			--ui) skip_ui=0 ;;
			-DNULLDC_DEVTOOLS_DIST=OFF) explicit_dist="OFF" ;;
			-DNULLDC_DEVTOOLS_DIST=*) explicit_dist="${arg#-DNULLDC_DEVTOOLS_DIST=}" ;;
		esac
	done

	# Load build args from user cfg or .cfg.default (same resolution as kosaio_reg_apply_config)
	local build_args=()
	_nulldc3_load_cfg_args build_args || return 1

	# A -DNULLDC_DEVTOOLS_DIST passed on the command line wins over the cfg file.
	if [ -n "$explicit_dist" ]; then
		local filtered=()
		local a
		for a in "${build_args[@]}"; do
			[[ "$a" == -DNULLDC_DEVTOOLS_DIST* ]] || filtered+=("$a")
		done
		build_args=("${filtered[@]}")
		[ "$explicit_dist" != "OFF" ] || skip_ui=1
	fi

	if [ "$skip_ui" -eq 0 ]; then
		_nulldc3_submodule_devtools "$tool_dir" || return 1
		_nulldc3_build_ui "$tool_dir" || return 1
	else
		log_warn "Skipping DevTools UI build; debugger will serve its fallback page."
		log_info "Tip: serve a prebuilt bundle at runtime with --config Debugger:WebRoot=<dist-native>"
	fi

	command -v ninja >/dev/null 2>&1 || { log_error "ninja not found. Run 'kosaio install-deps system' first."; return 1; }

	log_info --draw-line "Configuring nullDC 3 (CMake + Ninja)..."
	(cd "$tool_dir" && cmake -S . -B "${KOSAIO_TOOL_BUILD_DIR:-build}" -G Ninja "${build_args[@]}") || return 1

	log_info "Building nullDC 3..."
	cmake --build "${tool_dir}/${KOSAIO_TOOL_BUILD_DIR:-build}" -j"$(nproc)" || return 1

	log_success "nullDC 3 built: ${tool_dir}/${KOSAIO_TOOL_BUILD_DIR:-build}/nulldc3"
}

kosaio_tool_info() {
	local tool_dir
	tool_dir=$(__get_tool_dir)
	local binary="${tool_dir}/build/nulldc3"
	local status="${C_RED}Not Compiled${C_RESET}"
	[ -f "$binary" ] && status="${C_GREEN}Compiled${C_RESET}"

	local node_ver="not installed"
	command -v node >/dev/null 2>&1 && node_ver=$(node --version 2>/dev/null)

	local ui_status="${C_RED}missing${C_RESET}"
	[ -f "${tool_dir}/devtools/dist-native/index.html" ] && ui_status="${C_GREEN}built${C_RESET}"

	log_box --info "NULLDC3: REFERENCE DREAMCAST EMULATOR" \
		"${C_YELLOW}Status:${C_RESET}  ${status}" \
		"${C_YELLOW}Source:${C_RESET}  ${tool_dir}" \
		"${C_YELLOW}Node:${C_RESET}    ${node_ver} (needs >= v22.13 for the UI)" \
		"${C_YELLOW}UI:${C_RESET}      ${ui_status} (devtools/dist-native)" \
		"${C_YELLOW}BIOS:${C_RESET}    Optional (reios built-in); dc_boot.bin + dc_flash.bin in data/"
}

kosaio_tool_check_health() {
	local tool_dir
	tool_dir=$(__get_tool_dir)
	local binary="${tool_dir}/build/nulldc3"

	if [ ! -d "$tool_dir" ]; then
		log_box --info "nullDC 3 — Health Check" \
			"${C_YELLOW}Status:${C_RESET} ${C_RED}Not Installed${C_RESET}" \
			"" \
			"${C_RED}✗${C_RESET} Source missing at ${tool_dir}"
		return 1
	fi

	if [ ! -f "$binary" ]; then
		log_box --info "nullDC 3 — Health Check" \
			"${C_YELLOW}Status:${C_RESET} ${C_YELLOW}Not Compiled${C_RESET}" \
			"" \
			"${C_GREEN}✓${C_RESET} Source: ${tool_dir}" \
			"${C_RED}✗${C_RESET} Binary: ${binary}"
		return 2
	fi

	log_box --info "nullDC 3 — Health Check" \
		"${C_YELLOW}Status:${C_RESET} ${C_GREEN}Healthy${C_RESET}" \
		"" \
		"${C_GREEN}✓${C_RESET} Source: ${tool_dir}" \
		"${C_GREEN}✓${C_RESET} Binary: ${binary}"
	return 0
}

# ── helpers ──────────────────────────────────────────

# Init only the devtools submodule (skips tests/vendor/* vectors).
_nulldc3_submodule_devtools() {
	local tool_dir="$1"
	if [ ! -f "${tool_dir}/.gitmodules" ]; then
		return 0
	fi
	if [ -f "${tool_dir}/devtools/package.json" ]; then
		return 0
	fi
	log_info "Initializing devtools submodule (UI)..."
	(git -C "$tool_dir" submodule update --init devtools) || {
		log_error "Failed to init devtools submodule."
		return 1
	}
}

_nulldc3_build_ui() {
	local tool_dir="$1"

	if [ ! -f "${tool_dir}/devtools/package.json" ]; then
		log_error "devtools checkout missing package.json. Re-run 'kosaio clone nulldc3'."
		return 1
	fi

	if ! command -v node >/dev/null 2>&1; then
		log_error "Node.js not found (needs >= v22.13 for the DevTools UI)."
		log_info "Rebuild the image (provision installs Node.js 22 LTS) or build with --no-ui."
		return 1
	fi

	local node_ver
	node_ver=$(node --version 2>/dev/null | sed 's/^v//')
	local major=${node_ver%%.*}
	local rest=${node_ver#*.}
	local minor=${rest%%.*}
	if [ "$major" -lt "$KOSAIO_NULLDC3_MIN_NODE_MAJOR" ] || \
		{ [ "$major" -eq "$KOSAIO_NULLDC3_MIN_NODE_MAJOR" ] && [ "$minor" -lt "$KOSAIO_NULLDC3_MIN_NODE_MINOR" ]; }; then
		log_error "Node.js v${node_ver} too old (needs >= v22.13 for the DevTools UI)."
		log_info "Rebuild the image (provision installs Node.js 22 LTS) or build with --no-ui."
		return 1
	fi

	if [ -f "${tool_dir}/devtools/dist-native/index.html" ] && [ -f "${tool_dir}/devtools/dist-native/bundle-info.json" ]; then
		log_info "DevTools UI bundle already built; rebuilding to match pinned commit..."
	fi

	log_info "Building DevTools UI (npm ci + build:native)..."
	(cd "${tool_dir}/devtools" && npm ci && npm run build:native) || {
		log_error "DevTools UI build failed. Retry, or build with --no-ui."
		return 1
	}
}

# Mirrors the cfg resolution of kosaio_reg_apply_config, minus the configure step
# (this hook configures with -G Ninja itself).
_nulldc3_load_cfg_args() {
	local -n _out=$1
	_out=()

	local cfg_path="${KOSAIO_DIR}/data/cfg/nulldc3.cfg"
	local cfg_default="${KOSAIO_DIR}/scripts/registry/cfg/nulldc3.cfg.default"
	local cfg_file=""

	if [ -f "$cfg_path" ]; then
		cfg_file="$cfg_path"
	elif [ -f "$cfg_default" ]; then
		cfg_file="$cfg_default"
	fi

	if [ -n "$cfg_file" ]; then
		# shellcheck disable=SC1090
		source "$cfg_file"
		_out=("${KOSAIO_TOOL_ARGS[@]}")
	fi
}
