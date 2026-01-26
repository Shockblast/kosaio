# KOSAIO Architecture Reference

## 1. System Overview

**KOSAIO** (KallistiOS All-In-One) is an orchestration layer for the Sega Dreamcast development ecosystem. It serves as a unified interface to manage toolchains (KOS), libraries (Ports), and project environments.

It utilizes a **Hybrid Architecture**:
*   **Bash (The Shell Layer)**: Handles user interaction, environment pivoting (`source`), and process execution.
*   **Python (The Engine Layer)**: Handles complex logic, dependency resolution, text parsing, and state management.

## 2. Core Design Principles

### 2.1 The "Overlord" Pattern
The main script (`kosaio`) acts as an "Overlord". It does not contain business logic. Its job is to:
1.  Bootstrap the environment (`env.sh`, `deps.sh`).
2.  Load the Router.
3.  Dispatch the command to a specific Controller.

### 2.2 Single Source of Truth (SSoT)
To prevent "configuration drift" between the Shell environment and the Python engine, strict rules apply to Path Resolution:

*   **Runtime Authority**: The **Python Engine** (`services.validator`) is the single source of truth for where tools and ports are located during runtime.
*   **Bootstrap Fallback**: Bash functions (`env.sh`) are allowed to resolve paths **ONLY** during shell initialization (when Python might not be ready) or for exporting initial variables.

> **Rule**: If a script needs to know where `kos-ports` is installed, it MUST ask the Python Engine via `validate_get_tool_path`.

## 3. Directory Structure

```text
kosaio/
├── docs/                   # Documentation
├── scripts/
│   ├── kosaio              # Main Entry Point
│   ├── common/             # Shared Bash utilities (env, errors, ui, git, deps)
│   ├── controllers/        # Logic dispatchers (router, list, dev)
│   ├── engine/             # The Core Logic drivers
│   │   ├── py/             # Python Application (The Brain)
│   │   ├── ports/          # Port-specific Driver Scripts
│   │   └── driver_*.sh     # Native Drivers (Bridges)
│   └── registry/           # Tool Manifests
│       ├── core/           # KOS, KOS-Ports
│       ├── tools/          # Build/Asset utilities (dcaconv, mkdcdisc)
│       ├── libs/           # External libraries
│       ├── emu/            # Host emulators (flycast)
│       └── load/           # Hardware loaders (dcload-ip)
└── ...
```

## 4. Execution Flow

When a user runs `kosaio install libpng`:

1.  **Entry**: `kosaio` script initializes variables and sources `errors.sh`.
2.  **Routing**: `router.sh` identifies the action (`install`) and target (`libpng`).
3.  **Validation (Bash)**: Checks if `libpng` is a known "Port".
    *   *Internal Call*: Calls `ports_install "libpng"`.
4.  **Resolution (Python)**:
    *   `ports/core.sh` calls `python main.py resolve_deps libpng`.
    *   Python calculates the dependency graph (e.g., `zlib` -> `libpng`).
5.  **Execution (Bash)**:
    *   The Bash driver iterates over the resolved list.
    *   It enters the source directory (validated via `check_dir_soft`).
    *   It runs the standard `make install` commands.

## 5. Components Detail

### 5.1 The Registry
Located in `scripts/registry/`.
Contains `.sh` files that define Tools (compilers, debuggers, emulators).
*   **Format**: Bash-compatible variables (`ID`, `NAME`, `DESC`).
*   **Parsing**: Parsed by Python (via Regex) for speed and safety, sourced by Bash for installation logic.

### 5.2 The Ports Engine
Designed to wrap the official `kos-ports` ecosystem.
*   **Discovery**: Python scans `kos-ports/` Makefiles to dynamically discover available libraries.
*   **State Tracking**: Python compares the `kos-ports` folder state against `lib/.kos-ports` tracking files to determine what is installed.

### 5.3 Error Handling
Standardized via `common/errors.sh`.
*   Hardware-like failures (missing files, permissions) use `log_error` + `exit`.
*   Logic checks (search not found) use "Soft Checks" (return 1) to allow fallback logic.

## 6. Development & Testing
*   **Type Safety**: The Python engine is fully type-hinted (PEP 484) and marked as a package (`py.typed`).
*   **Verification**: `common/self_test.sh` verifies that the Bash layer and Python layer agree on critical paths.
