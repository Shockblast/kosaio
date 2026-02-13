#!/bin/bash
# scripts/registry/libs/aicaos.sh
# Manifest for AICAOS (Sound subsystem library/driver for Dreamcast)

ID="aicaos"
NAME="AICAOS"
DESC="Dedicated Operating System for the AICA (ARM7) Sound Chip"
TAGS="core,sound,aica,arm,audio,driver,os"
TYPE="core"
DEPS="build-essential git"

function reg_check_health() {
	local tool_dir=$(kosaio_get_tool_dir "$ID")
	[ -d "$tool_dir" ] || return 1
	
	# Check for compiled library and headers
	[ -f "${KOS_BASE}/addons/lib/dreamcast/libaicaos.a" ] || return 2
	[ -f "${KOS_BASE}/addons/include/aicaos/aica_sh4.h" ] || return 2
	return 0
}

function reg_info() {
	log_box --info "AICAOS: SOUND COPROCESSOR OS" \
		"${C_YELLOW}Context:${C_RESET} Runs autonomously on the ${C_MAGENTA}ARM7 Sound Chip${C_RESET} (SPU)." \
		"${C_YELLOW}Benefit:${C_RESET} Offloads audio processing, saving ${C_GREEN}main CPU power${C_RESET}." \
		"${C_YELLOW}Components:${C_RESET} ${C_CYAN}libaicaos.a${C_RESET} (SH4 Control) + ${C_CYAN}aicaos.drv${C_RESET} (ARM Firmware)"
}

function reg_clone() {
	local tool_dir=$(kosaio_get_tool_dir "$ID")
	log_info --draw-line "Cloning AICAOS..."
	kosaio_git_clone "https://github.com/Shockblast/AICAOS.git" "${tool_dir}"
}

function reg_build() {
	local tool_dir=$(kosaio_get_tool_dir "$ID")
	[ -d "$tool_dir" ] || { log_error "Source missing."; return 1; }

	# Check for ARM Toolchain (Required for AICAOS)
	if ! command -v arm-eabi-gcc &> /dev/null && [ ! -d "${DREAMCAST_SDK}/arm-eabi" ]; then
		log_error "ARM Toolchain missing. Please install toolchain with ARM support."
		log_info "AICAOS requires the ARM compiler to build the SPU driver."
		log_info "Tip: You may need to rebuild kos toolchain with ARM support enabled."
		return 3
	fi

	log_info --draw-line "Building AICAOS..."
	
	(
		cd "${tool_dir}"
		source "${KOS_BASE}/environ.sh"
		
		# 1. Build ARM driver
		log_info "Compiling ARM driver (SPU subsystem)..."
		make -C arm clean
		make -C arm aicaos.drv
		
		# 2. Build SH4 static library (The Sound OS API)
		log_info "Compiling SH4 library (User API)..."
		make -C sh4 clean
		
		# We compile the core components for the static library
		kos-cc -c sh4/aica_sh4.c -o sh4/aica_sh4.o
		kos-cc -c sh4/aica_syscalls.c -o sh4/aica_syscalls.o
		kos-cc -c aica_common.c -o aica_common.o
		
		# Create the archive using KOS toolchain
		${KOS_AR} rcs libaicaos.a sh4/aica_sh4.o sh4/aica_syscalls.o aica_common.o
	)
}

function reg_apply() {
	local tool_dir=$(kosaio_get_tool_dir "$ID")
	
	log_info "Integrating AICAOS into KOS addons..."
	
	# 1. Headers
	mkdir -p "${KOS_BASE}/addons/include/aicaos"
	cp -v "${tool_dir}/aica_common.h" "${KOS_BASE}/addons/include/aicaos/"
	cp -v "${tool_dir}/aica_registers.h" "${KOS_BASE}/addons/include/aicaos/"
	cp -v "${tool_dir}/aica_syscalls.h" "${KOS_BASE}/addons/include/aicaos/"
	cp -v "${tool_dir}/sh4/aica_sh4.h" "${KOS_BASE}/addons/include/aicaos/"
	
	# 2. Library
	mkdir -p "${KOS_BASE}/addons/lib/dreamcast"
	cp -v "${tool_dir}/libaicaos.a" "${KOS_BASE}/addons/lib/dreamcast/"
	
	# 3. Driver (Place it in a common drivers folder)
	#mkdir -p "${KOS_BASE}/addons/drivers"
	#cp -v "${tool_dir}/arm/aicaos.drv" "${KOS_BASE}/addons/drivers/"
	
	log_success "AICAOS integration complete."
	
	# Show post-install success/warning explicitly
	log_box --success "AICAOS: INSTALLATION SUCCESSFUL" \
		"1. CORE API: Library libaicaos.a installed in KOS addons." \
		"2. SPU DRIVER: Compiled aicaos.drv ready for loading." \
		"" \
		"IMPORTANT: You MUST load 'aicaos.drv' into the SPU" \
		"at the beginning of your SH4 program to use this OS." \
		"" \
		"STEPS TO DEPLOY:" \
		" - Run: ${C_CYAN}kosaio export aicaos${C_RESET}" \
		" - Place 'aicaos.drv' in a reachable DC path (e.g. /rd/)."
}

function reg_export() {
	local tool_dir=$(kosaio_get_tool_dir "$ID")
	local host_out="${KOSAIO_DIR}/out/aicaos"
	
	log_info "Exporting AICAOS artifacts to host..."
	
	if [ ! -f "${tool_dir}/arm/aicaos.drv" ] || [ ! -f "${tool_dir}/libaicaos.a" ]; then
		log_error "Compiled artifacts missing. Run 'kosaio build aicaos' first."
		return 1
	fi
	
	mkdir -p "${host_out}/include"
	
	# 1. Driver and Library
	cp -v "${tool_dir}/arm/aicaos.drv" "${host_out}/"
	cp -v "${tool_dir}/libaicaos.a" "${host_out}/"
	
	# 2. Headers
	cp -v "${tool_dir}/"*.h "${host_out}/include/"
	cp -v "${tool_dir}/sh4/aica_sh4.h" "${host_out}/include/"
	
	log_success "Export complete: ${host_out}/"
}

function reg_install() {
	reg_clone
	reg_build
	reg_apply
}

function reg_uninstall() {
	local tool_dir=$(kosaio_get_tool_dir "$ID")
	log_info "Uninstalling AICAOS..."
	
	rm -rf "${KOS_BASE}/addons/include/aicaos"
	rm -f "${KOS_BASE}/addons/lib/dreamcast/libaicaos.a"
	rm -f "${KOS_BASE}/addons/drivers/aicaos.drv"
	rm -rf "$tool_dir"
	
	log_success "AICAOS removed."
}

function reg_update() {
	local tool_dir=$(kosaio_get_tool_dir "$ID")
	kosaio_standard_update_flow "$ID" "$NAME" "$tool_dir" "$@"
}
