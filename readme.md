# KOSAIO (Kallistios All In One)

KOSAIO is an all-in-one Docker image with scripts to manage the installation and updating of the SDK tools designed to simplify homebrew development for the Sega Dreamcast. It contains a pre-configured development environment with KallistiOS (KOS) and a selection of essential tools, allowing you to start programming for the Dreamcast in the fastest and easiest way possible.

## Core Features

*   **Integrated Environment**: Comes with KOS and essential tools pre-configured.
*   **Granular Developer Mode**: Switch any tool between **Stable** (official releases) and **Developer Mode** (custom source code) individually.
*   **Smart Status Dashboard**: Use `kosaio list` to see instantly which tools are installed, which version is active, and their status.
*   **Automated Management**: Handles cloning, compilation, and dependency checks automatically.
*   **Project Scaffolding**: Create new projects ready to compile with a single command.

## Included Tools

You can install these tools with kosaio:

| Tool              | Description                                                                                         |
| ----------------- | --------------------------------------------------------------------------------------------------- |
| **KOS**           | KallistiOS, is the main open-source SDK for the Dreamcast.                                          |
| **KOS-PORTS**     | KOS-PORTS is a collection of third-party libraries ported to work with KOS.                         |
| **aldc**          | An OpenAL implementation for Dreamcast, facilitating 3D audio programming.                          |
| **gldc**          | An implementation of the OpenGL API for Dreamcast, facilitating 3D graphics development.            |
| **dcaconv**       | dcaconv converts audio to a format for the Dreamcast's AICA.                                        |
| **dcload-ip**     | Allows loading and executing binaries on the Dreamcast over a network (with a Broadband Adapter).   |
| **dcload-serial** | Allows loading and executing binaries on the Dreamcast via the serial port (with a "Coders Cable"). |
| **flycast**       | A Dreamcast emulator with GDB support, ideal for debugging and testing without real hardware.       |
| **makeip**        | Tool for creating 'IP.BIN' boot files for Dreamcast executables.                                    |
| **mkdcdisc**      | Allows creating disc images in CDI format, compatible with emulators and for burning to CD-R.       |
| **mksdiso**       | Utility for creating ISO images for SD loaders like GDEmu.                                          |
| **sh4zam**        | General-purpose library for math and linear algebra on Dreamcast.                                   |

* **Sh4zam**, **Aldc**, and **GLdc** are typically included in **KOS-PORTS**, but KOSAIO manages them as standalone tools so you can control them individually.
* **makeip** its already included in KOS but this is more updated.
* **flycast** emulator its compiles in container but works only in host and requires BIOS files installed in the host.
* Dependencies are installed automatically depending on the tool to be installed. If you have problems compiling something, you can use `kosaio doctor install_all_dependencies`.
* More tools will be implemented, if you want to help adapt them you can go to `scripts/in_progress`, if you know of a tool that is not there and you think it would be useful, you can suggest it in an issue.

## Prerequisites

To use KOSAIO, you must have **Podman** or **Docker** installed on your host system. The setup scripts will automatically detect and use either of these container engines.

### Quick Setup (Recommended)
The easiest way to set up your environment is using the assistant script. It will build the image and create the container with the correct volume mounts for local development.

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

### Manual Setup
The internal container path must be `/opt/projects` when creating the container; and in the host `/home/user/documents/projects` <-- here, this is where you will create all your projects.

### First Steps
The first SDK you need to install is KallistiOS (KOS). It is a long process, so be prepared for a break!

Before installing kos, if you like, you can look at the Makefile.cfg file inside the dc-chain-settings folder and make adjustments if required.

```bash
kosaio install kos
```

After that renember to exit terminal for refresh the enviroment.

Now you are ready to develop a dreamcast application, you can use the basic-project to test if KOS its working.

`kosaio create project mygame`

### Diagnostic and Health Checks

KOSAIO provides a powerful diagnosis system to ensure your environment is correctly configured.

*   **System Check**: `kosaio diagnose system` (Checks variable paths and toolchains).
*   **KOSAIO Health**: `kosaio diagnose self` (Checks if KOSAIO scripts are intact and up to date).
*   **SDK-Specific Check**: `kosaio diagnose kos` (Checks if KallistiOS is properly compiled).

### Developer Mode

KOSAIO offers a granular Developer Mode for advanced users who want to modify tools like `sh4zam` or `kos` without breaking their main stable installation.

#### Workflow:

1.  **Check Tool Status**:
    Use `list` to view the comprehensive status of all tools.
    ```bash
    kosaio list
    # Output Example:
    # sh4zam          Stable (Installed) / Dev (Installed - Active)
    ```
    This dashboard shows you at a glance:
    *   **Active Mode**: Which version (Stable or Dev) is currently enabled (marked as `- Active`).
    *   **Installation Status**: Whether the binary/library is actually present for each mode.

2.  **Enable Developer Mode**:
    Use `dev-switch` with `enable` to switch the tool's configuration to Developer Mode.
    ```bash
    kosaio dev-switch <tool> enable
    # Example: kosaio dev-switch sh4zam enable
    ```
    *   **Note**: This only changes the configuration. You must run the install command to apply the changes.

3.  **Apply Changes (Install Dev Version)**:
    Run the install command to clone (if needed), build, and install the development version of the tool.
    ```bash
    kosaio install <tool>
    ```

4.  **Disable Developer Mode (Revert)**:
    Use `dev-switch` with `disable` to switch the configuration back to Stable Mode.
    ```bash
    kosaio dev-switch <tool> disable
    ```
    *   **Note**: To restore the stable binary in your system, you must run `kosaio install <tool>` again.

### Examples

Some examples of how to use kosaio:

`kosaio install sh4zam`

`kosaio diagnose system`

`kosaio install-deps system`

`kosaio self-update`

### Debugging (Work in Progress, not ready yet)
This setup is designed to support debugging both on real hardware and with the Flycast emulator. The GDB client (`sh-elf-gdb`) always runs inside the container, while the GDB server runs on the target (either the Dreamcast itself or Flycast on your host machine).

-   **Flycast (Emulator)**: Since Flycast is a GUI application, it's best to run it on your host OS, not inside the container.
-   **Real Hardware (dcload-ip)**: dcload-ip from the container to the hardware.
-   **Real Hardware (dcload-serial)**: dcload-serial from the container to the hardware.

### TODO

- [ ] Complete the implementation of the tools in the `in_progress` folder, structuring them like the other scripts.
- [ ] Refine the debugging workflow to be even more seamless.
