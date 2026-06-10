#!/bin/bash
# scripts/registry/hooks/aicaos.sh
# Tool hooks for AICAOS: custom build (ARM driver + SH4 lib), install, export
# Loaded automatically by helper_loader.sh

kosaio_tool_info() {
	log_box --info "AICAOS: SOUND COPROCESSOR OS" \
		"${C_YELLOW}Context:${C_RESET} Runs autonomously on the ${C_MAGENTA}ARM7 Sound Chip${C_RESET} (SPU)." \
		"${C_YELLOW}Benefit:${C_RESET} Offloads audio processing, saving ${C_GREEN}main CPU power${C_RESET}." \
		"${C_YELLOW}Components:${C_RESET} ${C_CYAN}libaicaos.a${C_RESET} (SH4 Control) + ${C_CYAN}aicaos.drv${C_RESET} (ARM Firmware)"
}

kosaio_tool_build() {
	local tool_dir=$(__get_tool_dir)

	if ! command -v arm-eabi-gcc &> /dev/null && [ ! -d "${DREAMCAST_SDK}/arm-eabi" ]; then
		log_error "ARM Toolchain missing. Please install toolchain with ARM support."
		return 3
	fi

	log_info --draw-line "Building AICAOS..."

	(
		cd "${tool_dir}"
		source "${KOS_BASE}/environ.sh"

		log_info "Compiling ARM driver (SPU subsystem)..."
		make -C arm clean
		make -C arm aicaos.drv

		log_info "Compiling SH4 library (User API)..."
		make -C sh4 clean

		kos-cc -c sh4/aica_sh4.c -o sh4/aica_sh4.o
		kos-cc -c sh4/aica_syscalls.c -o sh4/aica_syscalls.o
		kos-cc -c aica_common.c -o aica_common.o

		${KOS_AR} rcs libaicaos.a sh4/aica_sh4.o sh4/aica_syscalls.o aica_common.o
	)
}

kosaio_tool_apply() {
	local tool_dir=$(__get_tool_dir)

	log_info "Integrating AICAOS into KOS addons..."

	mkdir -p "${KOS_BASE}/addons/include/aicaos"
	cp -v "${tool_dir}/aica_common.h" "${KOS_BASE}/addons/include/aicaos/"
	cp -v "${tool_dir}/aica_registers.h" "${KOS_BASE}/addons/include/aicaos/"
	cp -v "${tool_dir}/aica_syscalls.h" "${KOS_BASE}/addons/include/aicaos/"
	cp -v "${tool_dir}/sh4/aica_sh4.h" "${KOS_BASE}/addons/include/aicaos/"

	mkdir -p "${KOS_BASE}/addons/lib/dreamcast"
	cp -v "${tool_dir}/libaicaos.a" "${KOS_BASE}/addons/lib/dreamcast/"

	log_box --success "AICAOS: INSTALLATION SUCCESSFUL" \
		"Headers installed to: ${C_CYAN}${KOS_BASE}/addons/include/aicaos/${C_RESET}" \
		"Library installed to: ${C_CYAN}${KOS_BASE}/addons/lib/dreamcast/${C_RESET}" \
		"" \
		"${C_YELLOW}To use AICAOS in your project:${C_RESET}" \
		"  ${C_YELLOW}1.${C_RESET} Include headers: ${C_CYAN}#include <aicaos/aica_common.h>${C_RESET}" \
		"  ${C_YELLOW}2.${C_RESET} Link library:   ${C_CYAN}-laicaos${C_RESET}" \
		"  ${C_YELLOW}3.${C_RESET} Deploy driver:  ${C_CYAN}aicaos.drv${C_RESET} from ${C_CYAN}arm/${C_RESET} to your disc/ramdisk"
}

kosaio_tool_export() {
	local tool_dir=$(__get_tool_dir)
	local host_out="${KOSAIO_DIR}/out/aicaos"

	if [ ! -f "${tool_dir}/arm/aicaos.drv" ] || [ ! -f "${tool_dir}/libaicaos.a" ]; then
		log_error "Compiled artifacts missing. Run 'kosaio build aicaos' first."
		return 1
	fi

	mkdir -p "${host_out}/include"

	cp -v "${tool_dir}/arm/aicaos.drv" "${host_out}/"
	cp -v "${tool_dir}/libaicaos.a" "${host_out}/"
	cp -v "${tool_dir}/"*.h "${host_out}/include/"
	cp -v "${tool_dir}/sh4/aica_sh4.h" "${host_out}/include/"

	log_success "Export complete: ${host_out}/"
}
