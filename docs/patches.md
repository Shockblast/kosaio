# Tool Patches

This directory documents patches applied to external tools during the build process.
Patches are stored alongside each tool in `scripts/registry/patches/<tool>/`.

## kos-chain

Patches that modify the official `dc-chain` scripts to enable features required by modern libraries like AICAOS.

Applied to `kos/utils/dc-chain/scripts/`.

### Patches

- **001-init-arm-vars.patch**: Defines target-specific compiler variables for the ARM7DI (AICA) core.
- **002-newlib-cc-target.patch**: Modifies the Newlib build process to allow architecture-switching of the compiler during toolchain creation.
- **003-build-arm-full.patch**: Relaxes the "SH4-only" restriction for Newlib and enables a full **Pass 2** build for the ARM toolchain, providing a complete C Standard Library (Newlib) for SPU development.
