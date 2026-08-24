# AGENTS.md

Guía para agentes de IA (y colaboradores) que trabajan en **KOSAIO** (KallistiOS All In One).

## Qué es este proyecto

KOSAIO es un **orquestador / gestor de SDK y toolchain** para desarrollo homebrew de **Sega Dreamcast**. No compila juegos por sí mismo: gestiona la instalación, actualización, compilación y el "modo híbrido" de herramientas como KallistiOS (KOS), kos-ports, toolchains SH4/ARM, emuladores (flycast, mame, deecy, nitrocast), SDL2/SDL3, etc., dentro de un contenedor Podman/Docker.

- El código se ejecuta **dentro del contenedor** (`/opt/kosaio`), que monta este repo en vivo. Editar en el host se refleja al instante en el contenedor.
- `kosaio-setup.sh` (host) construye la imagen y crea el contenedor. `kosaio-shell` entra al contenedor.
- El comando principal es `kosaio <action> <target> [args]`, definido en `scripts/kosaio`.

## Arquitectura (Híbrida)

Dos capas que se comunican por CLI:

1. **Bash (Capa Shell / Orquestación)**: `scripts/` — interacción con el usuario, ejecución de procesos, environment. Recoge toda la UI, colores y helpers.
2. **Python (Capa Motor / Cerebro)**: `scripts/engine/py/` — lógica compleja y "Single Source of Truth" (SSoT): validación de targets, resolución de rutas, resolución de dependencias y búsqueda. Totalmente tipado (PEP 484, `py.typed`).

### Patrón "Overlord"

`scripts/kosaio` **no contiene lógica de negocio**. Solo:
1. Resuelve `KOSAIO_DIR` y parsea hot-flags (`--dev-host`/`--dev-cont`).
2. Carga `scripts/common/env.sh`, UI, deps, errors y utilidades.
3. Carga drivers y el router.
4. Despacha a `kosaio_router_dispatch` en `scripts/controllers/router.sh`.

### Regla SSoT (CRÍTICA)

- **El Motor Python es la única autoridad** para: identificar tipos de target, resolver rutas de herramientas y resolver dependencias de ports.
- **Si un script Bash necesita saber dónde está una herramienta o qué tipo es un target, DEBE preguntar a Python** (ver "Puente Bash ↔ Python").
- Bash **solo** puede resolver rutas durante el bootstrap de la shell (`env.sh`, cuando Python aún no está listo).

### Puente Bash ↔ Python

Bash delega vía `scripts/engine/py/main.py` (CLI con subcomandos). Comandos clave:

| Función Bash | Comando Python |
|---|---|
| `kosaio_validate_get_target_type <t> <action>` | `python3 main.py validate_target <t> --action <a>` (exit 0=ok, 1=no existe, 3=falta dep) |
| `kosaio_validate_get_tool_path <t> [mode]` | `python3 main.py get_tool_path <t> [--mode dev\|sys]` |
| Resolver deps de ports | `python3 main.py resolve_deps <lib>...` |
| Metadata de un port | `python3 main.py port_info <lib>` |
| Búsqueda | `python3 main.py search <query> [--installed]` |
| Nombre canónico de port | `python3 main.py resolve_port_name <name>` |
| IDs instalados | `python3 main.py get_installed_ids` |

Los `driver_*.sh` en `scripts/engine/` son los adaptadores que envuelven estas llamadas. `driver_validator.sh` traduce exit codes de Python a `log_error`/`log_warn` con mensajes amigables.

## Estructura de directorios

```
kosaio/
├── kosaio-setup.sh          # Setup del host (build imagen + crea contenedor)
├── kosaio-shell             # Helper para entrar al contenedor (generado)
├── kosaio.cfg(.template)    # Config del host (PROJECTS_HOST_DIR, TOOL)
├── readme.md                # Documentación de usuario
├── configs/                 # Configs de kos-chain (kos-v2/v3-dreamcast.cfg, aica.cfg, apt)
├── docker/Dockerfile        # Imagen (Ubuntu 24.04 + provision.sh)
├── basic-project/           # Plantilla para `kosaio create-project`
├── docs/                    # ARCHITECTURE.md, DEVELOPMENT_WORKFLOW.md, etc.
├── assets/                  # Banners/imágenes
├── data/                    # Estado en runtime (ver abajo)
└── scripts/
    ├── kosaio               # Entry point (Overlord)
    ├── shell-init.sh        # Inicializa la shell del contenedor (prompt HUD, kreload)
    ├── provision.sh         # Provisiona el contenedor (deps, dirs, permisos)
    ├── common/              # Librerías Bash compartidas (env, ui, git_utils, state, ...)
    ├── controllers/         # Despachadores: router.sh, list.sh, dev.sh, tool.sh
    ├── engine/
    │   ├── driver_*.sh      # Bridges Bash→Python (manager, validator, health, search, refresh)
    │   ├── diagnostics/     # self.sh, system.sh (checks)
    │   ├── ports/           # Gestión de kos-ports (core, lifecycle, checks, utils)
    │   └── py/              # Motor Python (SSoT) + tests (pytest)
    └── registry/            # Manifiestos y recetas de herramientas
        ├── tools/*.tool     # Manifiestos (variables KOSAIO_TOOL_*)
        ├── hooks/*.sh       # Hooks por herramienta (override de kosaio_reg_*)
        ├── cfg/*.cfg.default# Configs de build editables por el usuario
        ├── mk/*.mk          # Flags CFLAGS/LDFLAGS para proyectos de usuario
        ├── patches/         # Parches de fuente por herramienta
        └── process-standard.sh  # Plantilla genérica de ciclo de vida
```

## El Registro (Registry)

Cada herramienta instalable se define en `scripts/registry/`:

- **`tools/<id>.tool`**: manifiesto con variables `KOSAIO_TOOL_*` (id, name, desc, tags, type, repo, branch, deps, build system, install method, libs, include dirs, mensajes, etc.). Ver `kos.tool` como ejemplo canónico.
- **`hooks/<id>.sh`** (opcional): define funciones `kosaio_tool_*` (`kosaio_tool_clone`, `kosaio_tool_build`, `kosaio_tool_apply`, `kosaio_tool_update`, `kosaio_tool_info`, `kosaio_tool_check_health`, `kosaio_tool_install`...) que **sustituyen** a las `kosaio_reg_*` genéricas. Ejemplo: `kos.sh`, `kos-chain.sh`.
- **`cfg/<id>.cfg.default`** (opcional): flags de build editables por el usuario (p. ej. opciones CMake para SDL). El usuario los copia a `data/cfg/<id>.cfg` con `kosaio config <id>`.
- **`patches/<id>/`** (opcional): parches aplicados al clonar.
- **`process-standard.sh`**: plantilla genérica con las funciones `kosaio_reg_clone/build/apply/update/uninstall/clean/info/install`. El flujo estándar de install = `clone` → `build` → `apply` → marcar estado.

**Cómo se carga una herramienta** (`driver_manager.sh` → `kosaio_manager_execute`):
1. Resuelve la ruta del manifiesto con Python (`get_manifest_path`).
2. Carga config del tool, helpers y `process-standard.sh`.
3. Si el manifiesto no es la plantilla, lo sourcea como override.
4. Ejecuta `kosaio_reg_<accion>`, que a su vez usa el hook `kosaio_tool_<accion>` si existe (`declare -F kosaio_tool_<accion>`).

**Añadir una herramienta nueva** = crear `tools/<id>.tool` (+ hook/cfg/patches según necesidad). El parser Python y el loader Bash leen el `.tool` por regex / `source` respectivamente.

## Cómo fluye un comando

Ejemplo: `kosaio install libpng`

1. `scripts/kosaio` inicia env, hot-flags y carga todo.
2. `router.sh` identifica `install`/`libpng` → `_router_handle_lifecycle`.
3. `driver_validator.sh` → Python `validate_target libpng --action install` → tipo = `port`.
4. Router despacha a `ports_install` (`engine/ports/core.sh`).
5. `core.sh` resuelve dependencias con Python (`resolve_deps`) → confirma con el usuario.
6. Por cada lib: comprueba estado, hace `make install` en `$KOS_PORTS/<lib>`, genera manifiesto de archivos en `$KOS_BASE/.kos-manifest/<lib>.manifest` y tracking en `$KOS_PORTS/lib/.kos-ports/`.

Para `kosaio install kos` el target es `tool`/`core` → `kosaio_manager_execute` (flujo registry).

## Estado y modos (Container vs Host)

- **CONTAINER (System)**: herramienta instalada dentro de la imagen. Marca: `data/states/container/<tool>`.
- **HOST (Workspace)**: fuente/binarios en `$PROJECTS_DIR/kosaio-dev/<tool>` (visible en el host). Marca: `data/states/host/<tool>`.
- **`data/states/broken/<tool>`**: instalación fallida.
- `kosaio dev-switch <tool> host|container` alterna el modo (crea/borra la marca `host/`). Las marcas se gestionan con `kosaio_state_set/unset/get/list` de `scripts/common/state.sh`.
- **Hot flags**: `kosaio --dev-host <cmd>` (`-H`) o `--dev-cont <cmd>` (`-C`) fuerzan el modo solo para ese comando vía `KOSAIO_DEV_MODE`.
- **Regla de ports**: no se puede hacer `dev-switch` de un port individual; solo `kos-ports` como colección.
- **Resolución de rutas**: si un tool está en modo dev → `dev_root/<tool>`; si no, para los "holy list" (`kos`, `kos-ports`, `sh-elf`, `arm-eabi`, `aicaos`, `bin`) → `$DREAMCAST_SDK/<tool>`; resto → `data/repos/<tool>`. Todo esto vive en `Config.get_tool_dir` (`py/core/config.py`) y su fallback en `env.sh`.

## Variables de entorno importantes

- `KOSAIO_DIR` → raíz del repo (en contenedor: `/opt/kosaio`).
- `DREAMCAST_SDK` → `/opt/toolchains/dc`.
- `PROJECTS_DIR` / `PROJECTS_HOST_DIR` → raíz de proyectos del usuario.
- `KOSAIO_DEV_ROOT` → `${PROJECTS_DIR}/kosaio-dev`.
- `KOS_DIR`, `KOS_PORTS`, `KOS_BASE`, `KOSAIO_BIN_PATH`, `KOSAIO_MK`.
- `KOSAIO_DEV_MODE` → `1`=host, `0`=container (hot flags).
- `KOSAIO_AUTO_STASH` → activa/desactiva auto-stash en updates (`false` lo desactiva).
- `KOSAIO_NON_INTERACTIVE=1` → sin prompts (CI). `KOSAIO_BULK_UPDATE=1` → update masivo.
- `KOSAIO_CLEAN_AFTER`, `KOSAIO_LOG_MODE`, `KOSAIO_BRANCH`.

## Convenciones de código

- **Bash**: `set -Eeuo pipefail` en scripts no interactivos; nombres de funciones con prefijo `kosaio_*` (genéricas `kosaio_reg_*`, hooks `kosaio_tool_*`, helpers `kosaio_*_*`); UI con funciones de `common/ui.sh` (`log_info`, `log_warn`, `log_error`, `log_success`, `log_box`, `confirm`); colores via `C_*`; sourceear librerías comunes en lugar de duplicar. Debe pasar `shellcheck -x` (`.shellcheckrc` deshabilita SC1091 porque las rutas usan variables).
- **Python**: totalmente tipado (PEP 484); paquete marcado `py.typed`; estructura `core/` (modelos/lógica) y `services/` (servicios). No duplicar lógica de rutas/tipos en Bash.
- **NO hardcodear rutas**: siempre delegar a Python (`get_tool_path` / `kosaio_validate_get_tool_path`).

## Git y commits

- **Nunca crear commits, push ni PRs sin que el usuario lo pida explícitamente.** Si el usuario pide un cambio, haz los cambios y espera a que se solicite el commit.
- Antes de commitear: revisar `git status`, `git diff` y `git log --oneline -10`; stagear **solo** los archivos intencionados y nunca incluir secretos/keys.
- **Los mensajes deben seguir el estilo de los existentes** (`git log`): una sola línea corta en imperativo, en inglés mayormente, verbo al inicio (`Fix`, `Add`, `Update`, `Remove`, `Migrate`, `Rename`, `Disable`, `Clean`, `Refactor`, `Style`, `State`...). Se permite un prefijo corto con el tool/área afectada seguido de `:` (p. ej. `img4dc: change repository url`). Sin emojis, sin cuerpo extenso salvo que haga falta contexto.
- Ejemplos reales del repo:
  - `img4dc: change repository url`
  - `Fix shellcheck SC2034 in dev.sh`
  - `Add auto-stash protection for dirty working tree on update`
  - `Style: replace ((var++)) with var=$((var+1)) for set -e safety`
  - `State refactor: container/host/broken scopes with centralized helpers`

## Códigos de retorno en `update`

- `10` = sin cambios / ya actualizado (SKIP).
- `11` = actualizado y reconstruido.
- `12` = código actualizado, build saltado.

## Testing y verificación

- **Tests Python**: `python -m pytest -v --tb=short` desde `scripts/engine/py/` (usan pytest; `pyproject.toml` define `testpaths = ["tests"]`).
- **Lint Bash**: `shellcheck -x scripts/kosaio`, `shellcheck -x scripts/common/*.sh`, `shellcheck -x scripts/engine/driver_manager.sh`, `shellcheck -x scripts/controllers/*.sh`.
- **CI** (`.github/workflows/ci.yml`): ejecuta tests de Python y shell-lint en cada push/PR a `main`.
- Diagnóstico manual: `kosaio diagnose system|self|<id>`.

## Referencias de documentación

- `docs/ARCHITECTURE.md` — diseño del sistema, SSoT, estructura.
- `docs/DEVELOPMENT_WORKFLOW.md` — guía de modo híbrido.
- `docs/TERMINAL_HUD.md` — prompt y helpers de la shell.
- `readme.md` — documentación de usuario (herramientas, comandos, SDL, auto-stash).
- `docs/FUTURE_IDEAS.md` — herramientas candidatas.