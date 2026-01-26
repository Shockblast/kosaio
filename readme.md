# KOSAIO (KallistiOS All In One)

KOSAIO is an all-in-one Docker image with scripts to manage the installation and updating of the SDK tools designed to simplify homebrew development for the Sega Dreamcast. It contains a pre-configured development environment with KallistiOS (KOS) and a selection of essential tools, allowing you to start programming for the Dreamcast in the fastest and easiest way possible.

![KOSAIO Capture](capture.png)

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

*   **Integrated Environment**: Comes with KOS and essential tools pre-configured.
*   **Granular Hybrid Mode**: Switch any tool between **Container** (system) and **Host** (workspace) individually.
*   **Smart Status Dashboard**: Use `kosaio list` to see instantly which tools are installed and which mode is active.
*   **Hot-Swap Environment**: Refresh your SDK variables instantly with `kos-env` without restarting the shell.
*   **Project Scaffolding**: Create new projects ready to compile with `kosaio create-project <name>`.
*   **Terminal HUD**: A dynamic prompt that shows your current region (Host/Container) and system health.

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
| **lxdream-nitro** | A high-fidelity Dreamcast emulator (Community Edition).                                             |
| **makeip**        | Tool for creating 'IP.BIN' boot files for Dreamcast executables.                                    |
| **mkdcdisc**      | Allows creating disc images in CDI format, compatible with emulators and for burning to CD-R.       |
| **mksdiso**       | Utility for creating ISO images for SD loaders like GDEmu.                                          |
| **img4dc**        | Tools for working with Dreamcast disc images (CDI/MDS).                                             |

* **KOS-PORTS Library Management**: You can now install individual libraries (like **Sh4zam**, **GLdc**, **SDL**) directly using `kosaio clone kos-ports` and `kosaio install <library>`.
* **makeip** is already included in KOS, but this version is more updated.
* **flycast** and **lxdream-nitro** emulators compile in the container but run on the host. Both require BIOS files installed on the host.
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
> Before installing KOS, you can look at the `Makefile.cfg` file inside the `dc-chain-settings` folder and make adjustments if required (like changing GCC version).

```bash
kosaio install kos
```

> [!IMPORTANT]
> After installing KOS, you don't need to exit! Just run **`kos-env`** (or the shortcut **`kenv`**) to activate the new environment instantly.

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
    
    # Refresh the variables in your current shell
    kenv
    ```

3.  **Manage Sources**:
    - `kosaio clone <tool>`: Downloade source code to the host.
    - `kosaio build <tool>`: Compile from source.
    - `kosaio apply <tool>`: Register the built binaries.

4.  **Back to Stable**:
    ```bash
    kosaio dev-switch kos container
    kenv
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
- **`kenv`**: Hot-swap environment variables after a `dev-switch`.
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
