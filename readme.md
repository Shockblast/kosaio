# KOSAIO (Kallistios All In One)

KOSAIO is an all-in-one Docker image designed to simplify homebrew development for the Sega Dreamcast. It contains a pre-configured development environment with KallistiOS (KOS) and a selection of essential tools, allowing you to start programming for the Dreamcast in the fastest and easiest way possible.

## Included Tools

This image contains the following tools:

| Tool                        | Description                                                                                                         |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| **kosaio**                  | Script to manage the installation and updating of the SDK tools.                                                    |
| **KOS and KOS-PORTS**       | The main and fundamental SDK for Dreamcast development.                                                             |
| **aldc**                    | An OpenAL implementation for Dreamcast, facilitating 3D audio programming.                                          |
| **dcload-ip**               | Allows loading and executing binaries on the Dreamcast over a network (with a Broadband Adapter).                   |
| **dcload-serial**           | Allows loading and executing binaries on the Dreamcast via the serial port (with a "Coders Cable").                 |
| **flycast**                 | A Dreamcast emulator with GDB support, ideal for debugging and testing without real hardware (requires BIOS files). |
| **gldc**                    | An implementation of the OpenGL API for Dreamcast, facilitating 3D graphics development.                            |
| **make-ip**                 | Tool for creating 'IP.BIN' boot files for Dreamcast executables.                                                    |
| **mkdcdisc**                | Allows creating disc images in CDI format, compatible with emulators and for burning to CD-R.                       |
| **mksdiso**                 | Utility for creating ISO images for SD loaders like GDEmu.                                                          |
| **sh4zam**                  | General-purpose library for math and linear algebra on Dreamcast.                                                   |
| **create-project**          | Create a folder with a basic content and settings for vscode                                                        |
| **install-vscode-settings** | Predefined settings for Visual Studio Code, optimized for development with KOS.                                     |

### Prerequisites for creating the image
Make sure you have Docker or Podman installed on your system.

#### Docker
`sudo apt install docker`

#### Podman
`sudo apt install podman`

The internal container path must be `/opt/projects` when creating the container; and in the host `/home/user/documents/projects` <-- here, this is where you will create all your projects.

Opening the ports is optional as it is not fully implemented/configured for debugging in flycast, gdb and vscode, more in 'Debug'.
PORTS:
  - 3263 for flycast with gdb
  - 2159 for dcload-ip

### Debugging (Work in Progress)
This setup is designed to support debugging both on real hardware and with the Flycast emulator. The GDB client (`sh-elf-gdb`) always runs inside the container, while the GDB server runs on the target (either the Dreamcast itself or Flycast on your host machine).

-   **Flycast (Emulator)**: Since Flycast is a GUI application, it's best to run it on your host OS, not inside the container.
-   **Real Hardware (dcload-ip)**: dcload-ip from the container to the hardware.
-   **Real Hardware (dcload-serial)**: dcload-serial from the container to the hardware.

### TODO

- [ ] Complete the implementation of the tools in the `in_progress` folder, structuring them like the other scripts.
- [ ] Refine the debugging workflow to be even more seamless.
