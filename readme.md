# KOSAIO (Kallistios All In One)

KOSAIO is an all-in-one Docker image with scripts to manage the installation and updating of the SDK tools designed to simplify homebrew development for the Sega Dreamcast. It contains a pre-configured development environment with KallistiOS (KOS) and a selection of essential tools, allowing you to start programming for the Dreamcast in the fastest and easiest way possible.

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

* **Sh4zam**, **Aldc** and **GLdc** are already included in KOS-PORTS but its there for developers only.
* **makeip** its already included in KOS but this is more updated.
* **flycast** emulator its compiles in container but works only in host and requires BIOS files installed in the host.
* Dependencies are installed automatically depending on the tool to be installed. If you have problems compiling something, you can use `kosaio doctor install_all_dependencies`.
* More tools will be implemented, if you want to help adapt them you can go to `scripts/in_progress`, if you know of a tool that is not there and you think it would be useful, you can suggest it in an issue.

### Prerequisites for creating the image
Make sure you have Docker or Podman installed on your system host.

#### Docker
`sudo apt install docker`

or

#### Podman
`sudo apt install podman`

The internal container path must be `/opt/projects` when creating the container; and in the host `/home/user/documents/projects` <-- here, this is where you will create all your projects.


Opening the ports is optional as it is not fully implemented/configured for debugging in flycast, gdb and vscode, more in 'Debug'.
PORTS:
  - 3263 for flycast with gdb
  - 2159 for dcload-ip

### First steps

The first SDK you need to install is KallistiOS (KOS), you can install very easy with kosaio in you container, the installation and compilation will take a long time, so you can get up and take a break there.

Before installing kos, if you like, you can look at the Makefile.cfg file inside the dc-chain-settings folder and make adjustments if required.

`kosaio kos install`

After that renember to exit terminal for refresh the enviroment.

Now you are ready to develop a dreamcast application, you can use the basic-project to test if KOS its working.

`kosaio project create mygame`

This creates a basic project in `/home/user/documents/projects/mygame` (host) and `/opt/projects/mygame` (container), you can go there in the container terminal and use `make`, this compiles the project and creates a file `mygame/release/game.elf` in this file is a basic hello world, you can use a emulator to test it.

`kosaio flycast install`

When install flycast, this create a copy of a executable in the projects folder in the host `/home/user/documents/projects/` (renember to install dreamcast bios files in the host) open flycast and drag and drop the game.elf in the window or open bia flycast.

If everything went well, you should be able to see the message in the emulator and you are ready to continue on your own. If you need more tools or have problems, you can use kosaio or post an issue.

Some examples of how to use kosaio:

`kosaio sh4zam install`

`kosaio doctor install_all_dependencies`

`kosaio self-update`

### Debugging (Work in Progress, not ready yet)
This setup is designed to support debugging both on real hardware and with the Flycast emulator. The GDB client (`sh-elf-gdb`) always runs inside the container, while the GDB server runs on the target (either the Dreamcast itself or Flycast on your host machine).

-   **Flycast (Emulator)**: Since Flycast is a GUI application, it's best to run it on your host OS, not inside the container.
-   **Real Hardware (dcload-ip)**: dcload-ip from the container to the hardware.
-   **Real Hardware (dcload-serial)**: dcload-serial from the container to the hardware.

### TODO

- [ ] Complete the implementation of the tools in the `in_progress` folder, structuring them like the other scripts.
- [ ] Refine the debugging workflow to be even more seamless.
