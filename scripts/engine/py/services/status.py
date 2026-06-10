from pathlib import Path
from typing import Dict, Union
from core.config import cfg


class StatusService:
    @staticmethod
    def get_status_data(item_id: str, item_type: str) -> Dict[str, Union[str, bool]]:
        c_inst = cfg.get_installed_version(item_id, mode="0") is not None
        h_inst = cfg.get_installed_version(item_id, mode="1") is not None

        if item_type != "port":
            c_base, h_base = StatusService._resolve_bases(item_id)
            c_inst = c_base.exists()
            h_inst = h_base.exists()

            c_inst, h_inst = StatusService._apply_fallback(item_id, c_base, h_base, c_inst, h_inst)
            c_inst, h_inst = StatusService._run_specialized_check(item_id, c_base, h_base, c_inst, h_inst)

            # Generic tools (not in _SPECIAL_CASES): check .kosaio_installed marker
            if item_id not in StatusService._SPECIAL_CASES:
                if (c_base / ".kosaio_installed").exists():
                    c_inst = True
                elif c_base.exists():
                    c_inst = "c"  # cloned but not compiled
                else:
                    c_inst = False
                if (h_base / ".kosaio_installed").exists():
                    h_inst = True
                elif h_base.exists():
                    h_inst = "c"
                else:
                    h_inst = False

        is_host_active = StatusService._detect_active_mode(item_id, item_type)
        c_inst, h_inst = StatusService._detect_broken(item_id, is_host_active, c_inst, h_inst)
        c_source, h_source, c_inst, h_inst = StatusService._detect_port_source(item_id, item_type, c_inst, h_inst)

        return {
            "c_inst": "o" if c_inst is True else ("c" if c_inst == "c" or (c_source and item_type == "port") else "x"),
            "h_inst": "o" if h_inst is True else ("!" if h_inst == "!" else ("c" if h_inst == "c" or (h_source and item_type == "port") else "x")),
            "c_active": not is_host_active,
            "h_active": is_host_active,
        }

    # --- Internal helpers ---

    _HOLY_LIST = {"kos", "kos-ports", "sh-elf", "arm-eabi", "aicaos", "bin", "toolchain"}

    @staticmethod
    def _resolve_bases(item_id: str):
        if item_id in StatusService._HOLY_LIST:
            c_base = cfg.sdk_root / item_id
        else:
            c_base = cfg.kosaio_dir / "data" / "repos" / item_id
        h_base = cfg.dev_root / item_id
        return c_base, h_base

    @staticmethod
    def _apply_fallback(item_id: str, c_base: Path, h_base: Path, c_inst, h_inst):
        if not c_inst:
            c_alt = cfg.sdk_root / "kos-ports" / item_id
            if c_alt.exists():
                c_inst = True
        if not h_inst:
            h_alt = cfg.dev_root / "kos-ports" / item_id
            if h_alt.exists():
                h_inst = True
        return c_inst, h_inst

    @staticmethod
    def _run_specialized_check(item_id: str, c_base: Path, h_base: Path, c_inst, h_inst):
        handler = StatusService._SPECIAL_CASES.get(item_id)
        if handler:
            return handler(c_base, h_base, c_inst, h_inst)
        return c_inst, h_inst

    @staticmethod
    def _check_toolchain(c_base: Path, h_base: Path, c_inst, h_inst):
        c_sh = cfg.sdk_root / "sh-elf"
        c_arm = cfg.sdk_root / "arm-eabi"
        h_sh = cfg.dev_root / "sh-elf"
        h_arm = cfg.dev_root / "arm-eabi"

        c_has_sh = (c_sh / "bin" / "sh-elf-gcc").exists()
        c_has_arm = (c_arm / "bin" / "arm-eabi-gcc").exists()
        if c_has_sh:
            c_inst = True  # SH4 is sufficient; ARM is optional
        elif c_has_arm:
            c_inst = "c"
        else:
            c_inst = False

        h_has_sh = (h_sh / "bin" / "sh-elf-gcc").exists()
        h_has_arm = (h_arm / "bin" / "arm-eabi-gcc").exists()
        if h_has_sh:
            h_inst = True
        elif h_has_arm:
            h_inst = "c"
        else:
            h_inst = False

        return c_inst, h_inst

    @staticmethod
    def _check_kos(c_base: Path, h_base: Path, c_inst, h_inst):
        c_lib = c_base / "lib" / "dreamcast" / "libkallisti.a"
        if c_lib.exists():
            c_inst = True
        elif c_base.exists():
            c_inst = "c"
        else:
            c_inst = False

        h_lib = h_base / "lib" / "dreamcast" / "libkallisti.a"
        if h_lib.exists():
            h_inst = True
        elif h_base.exists():
            h_inst = "c"
        else:
            h_inst = False

        return c_inst, h_inst

    @staticmethod
    def _check_aicaos(c_base: Path, h_base: Path, c_inst, h_inst):
        kos_c = cfg.sdk_root / "kos"
        aica_lib_c = kos_c / "addons" / "lib" / "dreamcast" / "libaicaos.a"
        if aica_lib_c.exists():
            c_inst = True
        elif c_base.exists():
            c_inst = "c"
        else:
            c_inst = False

        h_drv = h_base / "arm" / "aicaos.drv"
        h_lib = h_base / "libaicaos.a"
        if h_drv.exists() and h_lib.exists():
            h_inst = True
        elif h_base.exists():
            h_inst = "c"
        else:
            h_inst = False

        return c_inst, h_inst

    _SPECIAL_CASES = {
        "toolchain": _check_toolchain,
        "kos": _check_kos,
        "aicaos": _check_aicaos,
    }

    @staticmethod
    def _detect_active_mode(item_id: str, item_type: str) -> bool:
        state_file = cfg.state_dir / f"{item_id}_dev"
        if state_file.exists():
            return True
        if item_type == "port":
            p_state = cfg.state_dir / "kos-ports_dev"
            return p_state.exists() or cfg.dev_mode == "1"
        return cfg.dev_mode == "1"

    @staticmethod
    def _detect_broken(item_id: str, is_host_active: bool, c_inst, h_inst):
        broken_marker = cfg.state_dir / f"{item_id}_broken"
        if broken_marker.exists():
            if is_host_active:
                h_inst = "!"
            else:
                c_inst = "!"
        elif is_host_active and item_id in {"kos", "kos-ports", "aicaos"} and h_inst is False:
            h_inst = "!"
        return c_inst, h_inst

    @staticmethod
    def _detect_port_source(item_id: str, item_type: str, c_inst, h_inst):
        c_source = False
        h_source = False
        if item_type == "port":
            h_ports_dir = cfg.get_tool_dir("kos-ports", force_mode="1")
            c_ports_dir = cfg.get_tool_dir("kos-ports", force_mode="0")

            h_source = (h_ports_dir / item_id / "dist").exists()
            h_inst_dir = (h_ports_dir / item_id / "inst").exists()
            c_source = (c_ports_dir / item_id / "dist").exists()
            c_inst_dir = (c_ports_dir / item_id / "inst").exists()

            if h_inst_dir:
                h_inst = True
            if c_inst_dir:
                c_inst = True
        return c_source, h_source, c_inst, h_inst
