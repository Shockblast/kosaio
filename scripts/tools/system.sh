#!/bin/bash
set -e

function info() {
    kosaio_echo "KOSAIO System Management Tool"
    echo "This tool manages the global SDK environment, dependencies, and health."
}

function install-core() {
	apt-get install -y git nano vim ca-certificates
	kosaio_echo "CORE SYSTEM TOOLS INSTALLED"
}

# Alias for backward compatibility
function install_basic_tools() {
    install-core
}

function check_required_vars() {
	local errors=0
	local SDK_DIR_LIST=(
		"DREAMCAST_SDK_EXTRAS"
		"DREAMCAST_SDK"
		"PROJECTS_DIR"
		"KOS_BASE"
		"KOS_PORTS"
	)

	for var_name in "${SDK_DIR_LIST[@]}"; do
		local path_val="${!var_name}"
		if [[ -z "$path_val" ]]; then
			kosaio_print_status "FAIL" "$var_name is NOT set."
			((errors++))
		elif [[ ! -d "$path_val" ]]; then
			kosaio_print_status "FAIL" "$var_name path does not exist: $path_val"
			((errors++))
		else
			kosaio_print_status "PASS" "$var_name - OK"
		fi
	done

	if [ "$errors" -ne 0 ]; then
		kosaio_echo "ENV VARS CHECK FAILED ($errors errors)."
		return 1
	fi
	kosaio_echo "ENV VARS CHECK PASSED."
}

function check_toolchain() {
	local errors=0
	if command -v sh-elf-gcc >/dev/null 2>&1; then
		echo "SH4 Toolchain - OK"
	else
		echo "Error: sh-elf-gcc not found."
		((errors++))
	fi

	if command -v arm-eabi-gcc >/dev/null 2>&1; then
		echo "ARM Toolchain - OK"
	else
		echo "Warning: arm-eabi-gcc not found."
	fi

	if [ "$errors" -ne 0 ]; then
		return 1
	fi
}

function fix-permissions() {
    if [ "$KOSAIO_DEV_MODE" == "1" ]; then
        kosaio_echo "Warning: Dev Mode enabled. Skipping standard permission checks on TARGET_DIRS as paths may vary."
    else
	    kosaio_set_folder_permission ${TARGET_DIRS}
	    kosaio_echo "SDK FOLDER PERMISSION FIXED."
    fi
}

# Alias for backward compatibility
function check_folder_permission() {
    fix-permissions
}

function install-deps() {
	kosaio_require_packages \
		bison build-essential bzip2 ca-certificates cmake curl \
		diffutils flex gawk genisoimage gettext git \
		libcurl4-openssl-dev libelf-dev libgmp-dev libisofs-dev libjpeg-dev \
		libmpc-dev libmpfr-dev libpng-dev libsdl2-dev libvulkan-dev make \
		meson nano ninja-build p7zip patch pkg-config \
		python3 python-is-python3 rake sed tar texinfo \
		vim wget wodim

	kosaio_echo "ALL SDK DEPENDENCIES INSTALLED."
}

# Alias
function install_all_dependencies() {
    install-deps
}


function diagnose() {
    kosaio_echo "Starting KOSAIO System Diagnosis..."
    local errors=0
    local warnings=0

    # 1. Environment Variables & Paths
    echo "--- Environment Check ---"
    local SDK_DIR_LIST=(
        "DREAMCAST_SDK_EXTRAS"
        "DREAMCAST_SDK"
        "PROJECTS_DIR"
        "KOS_BASE"
        "KOS_PORTS"
    )

    for var_name in "${SDK_DIR_LIST[@]}"; do
        local path_val="${!var_name}"
        if [[ -z "$path_val" ]]; then
            kosaio_print_status "FAIL" "$var_name is NOT set."
            ((errors++))
        elif [[ ! -d "$path_val" ]]; then
            kosaio_print_status "FAIL" "$var_name path does not exist: $path_val"
            ((errors++))
        else
            kosaio_print_status "PASS" "$var_name found."
        fi
    done

    # 2. Toolchain Check
    echo -e "\n--- Toolchain Check ---"
    if command -v sh-elf-gcc >/dev/null 2>&1; then
        local gcc_ver=$(sh-elf-gcc --version | head -n 1)
        kosaio_print_status "PASS" "SH4 GCC found: $gcc_ver"
    else
        kosaio_print_status "FAIL" "sh-elf-gcc not found in PATH."
        ((errors++))
    fi

    if command -v arm-eabi-gcc >/dev/null 2>&1; then
        local arm_ver=$(arm-eabi-gcc --version | head -n 1)
        kosaio_print_status "PASS" "ARM GCC found: $arm_ver"
    else
        kosaio_print_status "WARN" "arm-eabi-gcc not found (Sound compilation might fail)."
        ((warnings++))
    fi
    
    # 3. Connectivity
    echo -e "\n--- Network Check ---"
    if command -v curl >/dev/null 2>&1; then
        if curl -s --connect-timeout 5 --head https://github.com >/dev/null; then
            kosaio_print_status "PASS" "GitHub is reachable."
        else
            kosaio_print_status "WARN" "Could not reach GitHub. Cloning might fail."
            ((warnings++))
        fi
    else
        echo "curl not installed, skipping network check."
    fi

    echo -e "\n========================================"
    echo "System Diagnosis Complete: $errors Errors, $warnings Warnings."
    if [ "$errors" -ne 0 ]; then
        echo "Please fix the errors above to ensure a stable environment."
        exit 1
    else
        echo "System looks healthy! Happy Coding!"
        exit 0
    fi
}
