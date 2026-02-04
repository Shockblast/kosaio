# Terminal HUD & Interactive Shell

KOSAIO features a custom-built interactive shell designed to maximize productivity and provide immediate visual feedback on the state of your Dreamcast development environment.

## The Dynamic Prompt

The command prompt is inspired by the iconic SEGA Dreamcast visual language:

### 🌀 Region Swirl (The Environment)
The swirl symbol remains constant, but the **MODE** indicator next to it reflects your environment:
- **Orange [SYS]**: **CONTAINER** mode (US Style). You are using the stable system SDK.
- **Blue [DEV]**: **HOST** mode (JP/EU Style). You are using your local workspace/developer SDK.

### 🔻 Power LED (The Status)
The triangle indicates system health based on the last command's exit code **and** the specific health markers of your tools:
- **Orange LED 🔻**: **HEALTHY**. Your environment is ready and the last command succeeded.
- **Red LED 🛑**: **ERROR/PANIC**. The last command execution failed, or a tool state is marked as **BROKEN** (`!`).

## Shell Helpers

### Fast Navigation (`kcd`)
Stop typing long paths to your projects. 
- `kcd`: Jumps directly to the project root (`/opt/projects`).
- `kcd <name>`: Jumps to a specific project folder with tab-completion.

### Quick Environment Swapping (`kreload`)
Unified shortcut to trigger the pivot logic and UI refresh. Use this after changing modes with `kosaio dev-switch` to update your current terminal's variables and prompt instantly.

### Automated Completions
The shell includes smart tab-completions for:
- **kosaio**: Actions and targets.
- **kcd**: Project directory names.

---

## Technical Note: Asset Fidelity
KOSAIO uses standard Unicode Emojis (**🌀** and **🔻**) to provide an authentic SEGA-inspired experience across most modern terminal emulators without requiring custom icon patches (Nerd Fonts). 
