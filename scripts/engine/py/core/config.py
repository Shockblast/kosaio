import os
from pathlib import Path
from typing import Optional

class Config:
    def __init__(self):
        self.kosaio_dir = os.environ.get("KOSAIO_DIR", "/opt/kosaio")
        self.sdk_root = os.environ.get("DREAMCAST_SDK", "/opt/toolchains/dc")
        self.projects_root = os.environ.get("PROJECTS_DIR", "/opt/projects")
        self.dev_root = f"{self.projects_root}/kosaio-dev"
        self.state_dir = Path.home() / ".kosaio" / "states"
        self.dev_mode = os.environ.get("KOSAIO_DEV_MODE")
        self.kos_ports_dir_override = os.environ.get("KOS_PORTS_DIR")

    def get_tool_dir(self, tool: str, force_mode: Optional[str] = None) -> Path:
        mode = force_mode if force_mode is not None else self.dev_mode

        # Override only applies if NO forced mode is active
        if tool == "kos-ports" and self.kos_ports_dir_override and force_mode is None:
            return Path(self.kos_ports_dir_override)

        state_file = self.state_dir / f"{tool}_dev"

        # PRIORITY:
        # 1. mode == "1" (Forced Host)
        # 2. mode == "0" (Forced Container)
        # 3. Persistent state file
        
        is_dev = False
        if mode == "1":
            is_dev = True
        elif mode == "0":
            is_dev = False
        elif state_file.exists():
            is_dev = True

        # 1. Host / Dev Mode (Always in kosaio-dev root)
        if is_dev:
            return Path(self.dev_root) / tool

        # 2. System / Container Mode (Shared SDK)
        holy_list = {"kos", "kos-ports", "sh-elf", "arm-eabi", "aicaos", "extras", "bin"}
        if tool in holy_list:
            return Path(self.sdk_root) / tool
        else:
            # Everything else (Registry items) goes to extras/
            return Path(self.sdk_root) / "extras" / tool

    @property
    def kos_ports_dir(self) -> Path:
        return self.get_tool_dir("kos-ports")

    @property
    def system_kos_ports_dir(self) -> Path:
        """Returns the discovery path for kos-ports. Prefers system (container), fallbacks to host."""
        sys_path = Path(self.sdk_root) / "kos-ports"
        if sys_path.exists():
            return sys_path
        # Fallback to Host workspace version if system one is missing (e.g. running on host)
        return self.get_tool_dir("kos-ports", force_mode="1")

    @property
    def registry_dir(self) -> Path:
        return Path(self.kosaio_dir) / "scripts" / "registry"

    @property
    def diagnostics_dir(self) -> Path:
        return Path(self.kosaio_dir) / "scripts" / "engine" / "diagnostics"

    def get_installed_version(self, lib_name: str, mode: Optional[str] = None) -> Optional[str]:
        ports_dir = self.get_tool_dir("kos-ports", force_mode=mode)
        version_file = Path(ports_dir) / "lib" / ".kos-ports" / lib_name
        if version_file.exists():
            try:
                return version_file.read_text().strip()
            except:
                return None
        return None

cfg = Config()

