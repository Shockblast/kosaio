# Hybrid Workflow (Host & Container)

KOSAIO is designed to provide the best of both worlds: the stability of a pre-configured environment (Container) and the flexibility of your local development tools (Host).

## The Development Loop

When you want to modify a core component (like KallistiOS or a library like GLdc), follow this workflow:

### 1. Identify the Target
Use `kosaio list` to see if the tool is currently in "Container" or "Host" mode.
- **CONTAINER ◎**: Stable system version.
- **HOST ◎**: Your local workspace version.

### 2. Switch to Host Mode
Move the tool's pointer to your local workspace:
```bash
kosaio dev-switch kos host
```

### 3. Clone the Source
If you haven't already, download the source code to your host machine:
```bash
kosaio clone kos
```
The source will appear in `/opt/projects/kosaio-dev/kos` on your host.

### 4. Activate the Environment (The Hot-Swap)
This is a critical step. To tell your current terminal to use the new paths, run:
```bash
kenv
```
Your prompt will change to **[KOS:HOST]** with a **Blue ◎**.

### 5. Modify and Build
Now you can edit the files using your favorite IDE on your Host (VS Code, CLion, etc.). To compile your changes:
```bash
kosaio build kos
```

### 6. Apply to System
Once built, you need to register these binaries so other projects can see them:
```bash
kosaio apply kos
```

---

## Returning to Stability
If you want to go back to the official stable version:
1. `kosaio dev-switch kos container`
2. `kenv` (Your prompt returns to **Orange ◎**)

Now you are back to the "factory settings" of the Docker image.
