# Terminal HUD & Interactive Shell

KOSAIO features a custom-built interactive shell designed to maximize productivity and provide immediate visual feedback on the state of your Dreamcast development environment.

## The Dynamic Prompt

The command prompt is inspired by the iconic SEGA Dreamcast visual language:

### 🌀 Region Swirl (The Logo)
The swirl symbol indicates where your current environment variables are pointing:
- **Orange Swirl ◎**: **CONTAINER** mode (US Style). You are using the stable system SDK.
- **Blue Swirl ◎**: **HOST** mode (JP/EU Style). You are using your local workspace/developer SDK.

### 🔻 Power LED (The Status)
The triangle below the swirl represents the console's "Power LED" and indicates system health:
- **Orange LED ▼**: **HEALTHY**. Your environment is ready and the last command succeeded.
- **Red LED ▼**: **ERROR/PANIC**. The last command execution failed.

## Shell Helpers

### Fast Navigation (`kcd`)
Stop typing long paths to your projects. 
- `kcd`: Jumps directly to the project root (`/opt/projects`).
- `kcd <name>`: Jumps to a specific project folder with tab-completion.

### Quick Environment Swapping (`kenv`)
Manual shortcut to trigger the pivot logic. Use this after changing modes with `kosaio dev-switch` to update your current terminal's variables instantly.

### Automated Completions
The shell includes smart tab-completions for:
- **kosaio**: Actions and targets.
- **kcd**: Project directory names.

---

## Technical Note: Font Support
By default, KOSAIO uses standard Unicode symbols (**◎** and **▼**) to ensure compatibility. For a more authentic experience, it is recommended to use a pixel-art font like **Pixelify Sans** (included in `assets/font`) in your terminal settings.
