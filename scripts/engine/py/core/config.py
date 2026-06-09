import os
from pathlib import Path
from typing import Optional

class Config:
    def __init__(self):
        self.kosaio_dir = Path(os.environ.get("KOSAIO_DIR", "/opt/kosaio"))
        self.sdk_root = Path(os.environ.get("DREAMCAST_SDK", "/opt/toolchains/dc"))
        self.projects_root = Path(os.environ.get("PROJECTS_DIR", "/opt/projects"))
        self.dev_root = self.projects_root / "kosaio-dev"
        self.state_dir = Path.home() / ".kosaio" / "states"
        self.dev_mode = os.environ.get("KOSAIO_DEV_MODE")
        self.kos_ports_dir_override = os.environ.get("KOS_PORTS")

    def get_tool_dir(self, tool: str, force_mode: Optional[str] = None) -> Path:
        mode = force_mode if force_mode is not None else self.dev_mode

        # Override only applies if NO forced mode is active
        if tool == "kos-ports" and self.kos_ports_dir_override and force_mode is None:
            return Path(self.kos_ports_dir_override)

        state_file = self.state_dir / f"{tool}_dev"

        is_dev = False
        if mode == "1":
            is_dev = True
        elif mode == "0":
            is_dev = False
        elif state_file.exists():
            is_dev = True

        if is_dev:
            return self.dev_root / tool

        holy_list = {"kos", "kos-ports", "sh-elf", "arm-eabi", "aicaos", "bin"}
        if tool in holy_list:
            return self.sdk_root / tool
        else:
            return self.kosaio_dir / "repos" / tool

    @property
    def kos_ports_dir(self) -> Path:
        return self.get_tool_dir("kos-ports")

    @property
    def system_kos_ports_dir(self) -> Path:
        sys_path = self.sdk_root / "kos-ports"
        if sys_path.exists():
            return sys_path
        if self.kos_ports_dir_override:
            return Path(self.kos_ports_dir_override)
        return self.get_tool_dir("kos-ports", force_mode="1")

    @property
    def registry_dir(self) -> Path:
        return self.kosaio_dir / "scripts" / "registry"

    @property
    def diagnostics_dir(self) -> Path:
        return self.kosaio_dir / "scripts" / "engine" / "diagnostics"

    @property
    def config_tools_dir(self) -> Path:
        return self.kosaio_dir / "configs" / "tools"

    @property
    def template_path(self) -> Path:
        return self.registry_dir / "process-standard.sh"

    def get_installed_version(self, lib_name: str, mode: Optional[str] = None) -> Optional[str]:
        ports_dir = self.get_tool_dir("kos-ports", force_mode=mode)
        version_file = ports_dir / "lib" / ".kos-ports" / lib_name
        if version_file.exists():
            try:
                return version_file.read_text().strip()
            except:
                return None
        return None

cfg = Config()

