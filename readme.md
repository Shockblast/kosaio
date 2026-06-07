# KOSAIO (KallistiOS All In One)

> **The Autonomous Container-Suite for Dreamcast SDK Orchestration.**

KOSAIO bridges the gap between your Host OS and the SDK through a surgical hybrid architecture, creating a unified workspace for modern homebrew development.

![KOSAIO Unified HUD](assets/banner.png)

*The KOSAIO Master HUD showing a healthy, ready-to-use cross-compiler environment.*

> [!WARNING]  
> **Legacy Version Notice (January 2026)**  
> This version introduces a new **Hybrid Python-based architecture**.  
> If you wish to remain on the legacy version to avoid changes to your current workflow, please run:
> ```bash
> git fetch
> git checkout v1.x
> ```
> *If you have local changes preventing the switch, use `git stash` to save them or `git checkout -f v1.x` to force the transition and discard local script modifications.*


## Core Features

*   **⚡ Integrated Environment**: Comes with KOS and essential tools pre-configured and ready for action.
*   **🔄🔥 HOT SWAP Mode**: Switch any tool between **Container** (system) and **Host** (workspace) individually with `dev-switch`. Libraries follow a **Collection-First** model via `kos-ports`.
*   **🛠️ ARM & AICAOS Ready**: Full support for building custom sound drivers with automated ARM toolchain patching.
*   **📊 Smart Dashboard**: Use `kosaio list` to see instantly which tools are installed and which mode is active.
*   **🏠 Unified Workspace**: Develop on your Host OS (Antigravity/VSCode/NeoVim) while compiling inside the container effortlessly.
*   **📟 Terminal HUD**: A dynamic prompt that shows your current region (Host/Container) and system health.

## Included Tools

You can install these tools with kosaio:

| Tool              | Description                                                                                         |
| ----------------- | --------------------------------------------------------------------------------------------------- |
| **KOS**           | KallistiOS, is the main open-source SDK for the Dreamcast.                                          |
| **KOS-PORTS**     | KOS-PORTS is a collection of third-party libraries ported to work with KOS.                         |
| **dcaconv**       | dcaconv converts audio to a format for the Dreamcast's AICA.                                        |
| **dcload-ip**     | Allows loading and executing binaries on the Dreamcast over a network (with a Broadband Adapter).   |
| **dcload-serial** | Allows loading and executing binaries on the Dreamcast via the serial port (with a "Coders Cable"). |
| **flycast**       | A Dreamcast emulator with GDB support, ideal for debugging and testing without real hardware.       |
| **nitrocast**     | A high-fidelity Dreamcast emulator (Community Edition).                                             |
| **makeip**        | Tool for creating 'IP.BIN' boot files for Dreamcast executables.                                    |
| **mkdcdisc**      | Allows creating disc images in CDI format, compatible with emulators and for burning to CD-R.       |
| **mksdiso**       | Utility for creating ISO images for SD loaders like GDEmu.                                          |
| **img4dc**        | Tools for working with Dreamcast disc images (CDI/MDS).                                             |
| **AICAOS**        | Advanced sound driver for Dreamcast (ARM side).                                                     |
| **mame**          | Multiple Arcade Machine Emulator (Optimized for Dreamcast). Requires 'dc.zip'.                      |
| **SDL2**          | Simple DirectMedia Layer 2 (vanilla, compiled with container GCC into `/usr/local`).                |
| **SDL3**          | Simple DirectMedia Layer 3 (vanilla, compiled with container GCC into `/usr/local`).                |
| **SDL2-DC**       | SDL2 port for Dreamcast by GPF (cross-compiled with KOS toolchain into `${KOS_BASE}/addons`).       |
| **SDL3-DC**       | SDL3 port for Dreamcast by GPF (cross-compiled with KOS toolchain into `${KOS_BASE}/addons`).       |

* **KOS-PORTS Library Management**: You can now install individual libraries (like **Sh4zam**, **GLdc**, **SDL**) directly using `kosaio clone kos-ports` and `kosaio install <library>`.
* **SDL Build Customization**: All SDL variants (`sdl2`, `sdl3`, `sdl2-dc`, `sdl3-dc`) accept flags to customize the build — use `--no-audio`, `--no-joystick`, `--no-opengl`, etc. to disable subsystems and produce leaner builds. See [SDL Build Flags](#sdl-build-flags) below.
* **makeip** is already included in KOS, but this version is more updated.
* **flycast**, **nitrocast** and **mame** emulators compile in the container but run on the host. They require BIOS files installed on the host.
* Dependencies are installed automatically when a tool is requested. If you need to manually refresh them, use `kosaio install-deps system`.
* More tools will be implemented. If you want to contribute, check the `scripts/registry` structure. If you have a tool suggestion, please open an issue!

## Prerequisites

To use KOSAIO, you must have **Podman** or **Docker** installed on your host system. The setup scripts will automatically detect and use either of these container engines.

### Quick Setup (Recommended)
The easiest way to set up your environment is using the assistant script. It will build the image and create the container with the correct volume mounts for local development.

> [!IMPORTANT]  
> Before running the setup, you must create your configuration file:
> 1. Copy `kosaio.cfg.template` to `kosaio.cfg`.
> 2. Edit `kosaio.cfg` and set your projects directory and preferred tool (Docker or Podman).

1.  Make the script executable:
    ```bash
    chmod +x kosaio-setup.sh
    ```
2.  Run the setup:
    ```bash
    ./kosaio-setup.sh
    ```
3.  Enter the environment:
    ```bash
    ./kosaio-shell
    ```

> [!TIP]
> This method mounts your local KOSAIO folder into the container, allowing you to edit scripts on your host and see changes instantly inside Podman/Docker.

### First Steps
The first SDK you need to install is KallistiOS (KOS). It is a long process, so be prepared for a break!

> [!TIP]
> Before installing KOS, you can look at the `dc-chain-settings.cfg` file inside the `configs` folder and make adjustments if required (like changing GCC version).

```bash
kosaio install kos
```

> After installing KOS, you don't need to exit! Just run **`kreload`** to activate the new environment and refresh your shell instantly.

Now you are ready to develop a Dreamcast application. You can create a new project from a template:

```bash
kosaio create-project mygame
```

### Diagnostic and Health Checks

KOSAIO provides a powerful diagnosis system to ensure your environment is correctly configured.

*   **System Check**: `kosaio diagnose system` (Checks variable paths and toolchains).
*   **KOSAIO Health**: `kosaio diagnose self` (Checks if KOSAIO scripts are intact and up to date).
*   **SDK-Specific Check**: `kosaio diagnose kos` (Checks if KallistiOS is properly compiled).

KOSAIO offers a granular **Hybrid Mode** for advanced users who want to modify tools like `kos` or libraries like `libGL` directly from their Host OS.

#### Terminology:
- **CONTAINER (System)**: Uses the pre-installed, stable version inside the Docker image.
- **HOST (Workspace)**: Uses the source code and binaries from your local `/opt/projects/kosaio-dev/` folder, visible in the host.

#### Workflow:

1.  **Check Status**:
    ```bash
    kosaio list
    ```
    Shows which mode is active and if the tool is installed in that mode.

2.  **Switch Mode**:
    ```bash
    # Move KOS to your workspace
    kosaio dev-switch kos host
    
    # Refresh the variables and shell UI instantly
    kreload
    ```

3.  **Manage Sources**:
    - `kosaio clone <tool>`: Downloade source code to the host.
    - `kosaio build <tool>`: Compile from source.
    - `kosaio apply <tool>`: Register the built binaries.

4.  **Back to Stable**:
    ```bash
    kosaio dev-switch kos container
    kreload
    ```

### Examples

Some examples of how to use kosaio:

`kosaio install kos`

`kosaio clone kos-ports` # clone kos-ports to the host (recommended)

`kosaio diagnose system`

`kosaio install-deps system`

`kosaio update self`

`kosaio update libwav`

#### Advanced Interactive Shell
Enabling the KOSAIO shell provides a series of productivity helpers:
- **`kosaio list`**: Find libraries by name or description.
- **`kcd <project>`**: Fast jump to any project in your workspace.
- **`kreload`**: Hot-swap environment variables & prompt after a `dev-switch`.
- **Hot Actions**: Use `--dev-host` or `--dev-cont` to override mode for a single command.
- **Tab-Completions**: Full support for all `kosaio` commands.

#### Managing KOS-PORTS Libraries

Instead of building all kos-ports libraries, you can install only what you need:

```bash
# List all available libraries
kosaio list

# Get info about a specific library
kosaio info sh4zam

# Install only specific libraries
kosaio install sh4zam
kosaio install libpng zlib

# Update a specific library
kosaio update libgl

# Uninstall a library
kosaio uninstall sh4zam
```

#### SDL Build Flags

When building any of the 4 SDL variants (`sdl2`, `sdl3`, `sdl2-dc`, `sdl3-dc`), you can pass flags to enable/disable specific subsystems:

```bash
# Disable audio and joystick (useful if using ALDC or custom input)
kosaio build sdl2 -- --no-audio --no-joystick

# SDL3 and Dreamcast variants use CMake flags
kosaio build sdl3 -DSDL_AUDIO=OFF -DSDL_JOYSTICK=OFF
kosaio build sdl2-dc -DSDL_AUDIO=OFF -DSDL_HAPTIC=OFF

# Apply GPF-recommended settings (Dreamcast variants only)
kosaio build sdl2-dc -- --gpf-settings
```

The flags are translated automatically to the right format depending on the build system (configure or CMake):

| Flag | Effect |
|------|--------|
| `--no-audio` / `--disable-audio` | Disable audio subsystem |
| `--no-video` / `--disable-video` | Disable video subsystem |
| `--no-joystick` / `--disable-joystick` | Disable joystick subsystem |
| `--no-haptic` / `--disable-haptic` | Disable haptic (force feedback) |
| `--no-opengl` / `--disable-opengl` | Disable OpenGL support |
| `--no-pthreads` / `--disable-pthreads` | Disable POSIX threads |
| `--no-timers` / `--disable-timers` | Disable timer subsystem |
| `--no-render` / `--disable-render` | Disable render subsystem |
| `--no-events` / `--disable-events` | Disable events subsystem |
| `--no-sensor` / `--disable-sensor` | Disable sensor subsystem (CMake only) |
| `--no-hidapi` / `--disable-hidapi` | Disable HID API (CMake only) |
| `--no-tests` / `--disable-tests` | Disable test builds |
| `--static` / `--no-shared` | Build static library only |
| `--no-gpu` / `--disable-gpu` | Disable GPU subsystem (SDL3+) |
| `--no-camera` / `--disable-camera` | Disable camera subsystem (SDL3+) |
| `--no-dialog` / `--disable-dialog` | Disable dialog subsystem (SDL3+) |
| `--no-tray` / `--disable-tray` | Disable tray subsystem (SDL3+) |
| `--no-sh4zam` / `--disable-sh4zam` | Disable SH4ZAM acceleration (SDL3-DC) |
| `--no-vulkan` / `--disable-vulkan` | Disable Vulkan support (SDL3+) |
| `--no-openvr` / `--disable-openvr` | Disable OpenVR support (SDL3+) |
| `--no-render-gpu` / `--disable-render-gpu` | Disable GPU renderer (SDL3+) |
| `--gpf-settings` | Apply GPF-recommended defaults (Dreamcast variants only) |
| `--enable-audio` | Enable audio subsystem |
| `--enable-video` | Enable video subsystem |
| `--enable-joystick` | Enable joystick subsystem |
| `--enable-haptic` | Enable haptic (force feedback) |
| `--enable-opengl` | Enable OpenGL support |
| `--enable-pthreads` | Enable POSIX threads |
| `--enable-timers` | Enable timer subsystem |
| `--enable-render` | Enable render subsystem |
| `--enable-events` | Enable events subsystem |
| `--enable-sensor` | Enable sensor subsystem (CMake only) |
| `--enable-hidapi` | Enable HID API (CMake only) |
| `--enable-filesystem` | Enable filesystem subsystem |
| `--enable-tests` | Enable test builds |
| `--enable-shared` | Build shared library (inverse of `--static`) |
| `--enable-gpu` | Enable GPU subsystem (SDL3+) |
| `--enable-camera` | Enable camera subsystem (SDL3+) |
| `--enable-dialog` | Enable dialog subsystem (SDL3+) |
| `--enable-tray` | Enable tray subsystem (SDL3+) |
| `--enable-sh4zam` | Enable SH4ZAM acceleration (SDL3-DC) |
| `--enable-vulkan` | Enable Vulkan support (SDL3+) |
| `--enable-openvr` | Enable OpenVR support (SDL3+) |
| `--enable-render-gpu` | Enable GPU renderer (SDL3+) |

You can also pass raw CMake flags (`-DSDL_FOO=ON/OFF`) or configure flags (`--enable-foo`/`--disable-foo`) directly — they are passed through untouched.

### Direct Access to KOS Utilities
You can execute internal KOS tools directly without adding them to your PATH:

```bash
# Convert textures
kosaio tool pvrtex assets/image.png assets/image.pvr

# Create boot sector
kosaio tool makeip IP.TXT IP.BIN

# Scramble binary
kosaio tool scramble main.bin 1st_read.bin
```
Available tools: `pvrtex`, `vqenc`, `makeip`, `scramble`, `bin2o`, `wav2adpcm`, `kmgenc`, `dcbumpgen`.


### Advanced Documentation

For detailed technical information:

- **[Architecture](docs/ARCHITECTURE.md)** - System design, SSoT principles, and directory structure.
- **[Development Workflow](docs/DEVELOPMENT_WORKFLOW.md)** - Hybrid mode guide (Host vs Container).
- **[Terminal HUD](docs/TERMINAL_HUD.md)** - Details about the interactive shell prompts.
- **[Contributing](docs/INDEX.md)** - Documentation index and contributing guidelines.
- **[Future Ideas](docs/FUTURE_IDEAS.md)** - List of candidate tools and libraries for future integration.

### Debugging (Work in Progress, not ready yet)

This setup is designed to support debugging both on real hardware and with the Flycast emulator. The GDB client (`sh-elf-gdb`) always runs inside the container, while the GDB server runs on the target (either the Dreamcast itself or Flycast on your host machine).

-   **Flycast (Emulator)**: Since Flycast is a GUI application, it's best to run it on your host OS, not inside the container.
-   **Real Hardware (dcload-ip)**: dcload-ip from the container to the hardware.
-   **Real Hardware (dcload-serial)**: dcload-serial from the container to the hardware.

### TODO

- [ ] Refine the debugging workflow to be even more seamless.

---

### [Legal Disclaimer & Notices](DISCLAIMER.md)
*Dreamcast and SEGA are trademarks of SEGA Corporation. This project is AI-assisted and not affiliated with SEGA.*
