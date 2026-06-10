#!/bin/bash
# scripts/common/make.sh
# Helper for make-based tools

kosaio_make_build() {
	make -j"$(nproc)" "$@"
}
