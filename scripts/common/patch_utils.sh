#!/bin/bash
# scripts/common/patch_utils.sh
# Utilities for managing and applying patches to external projects

function kosaio_apply_patches() {
	local target_dir="$1"
	local patch_group="$2"
	local patches_dir="${KOSAIO_DIR}/patches/${patch_group}"

	if [ ! -d "$patches_dir" ]; then
		log_warn "No patches found for group: ${patch_group}"
		return 0
	fi

	if [ ! -d "$target_dir" ]; then
		log_error "Target directory for patching not found: ${target_dir}"
		return 1
	fi

	log_info "Applying patches for ${C_BLUE}${patch_group}${C_RESET}..."

	# Ensure we have git or patch installed (DEPS should cover this)
	local has_patch=false
	command -v patch &> /dev/null && has_patch=true

	for patch_file in $(find "$patches_dir" -name "*.patch" | sort); do
		local patch_name=$(basename "$patch_file")
		
		# 1. Check if already applied (can it be reversed?)
		if (cd "$target_dir" && patch -p1 -Rs --dry-run < "$patch_file" &> /dev/null); then
			log_info "  Skipping: ${patch_name} (Already applied)"
			continue
		fi

		# 2. Try to apply (dry run first for safety)
		if (cd "$target_dir" && patch -p1 -Ns --dry-run < "$patch_file" &> /dev/null); then
			log_info "  Applying: ${patch_name}..."
			if (cd "$target_dir" && patch -p1 -N < "$patch_file" &> /dev/null); then
				log_success "  Patched: ${patch_name}"
			else
				log_error "  Failed to apply: ${patch_name}"
				return 1
			fi
		else
			log_warn "  Warning: ${patch_name} cannot be applied (Conflict or already modified)."
		fi
	done

	return 0
}
