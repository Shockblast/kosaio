import os
from pathlib import Path
from typing import Dict, Any, Union
from core.config import cfg

class StatusService:
    @staticmethod
    def get_status_data(item_id: str, item_type: str) -> Dict[str, Union[str, bool]]:
        """
        Calculates the installation and active status of a tool or port
        for both Container (c) and Host (h) environments.
        """
        # Detections
        c_inst = cfg.get_installed_version(item_id, mode="0") is not None
        h_inst = cfg.get_installed_version(item_id, mode="1") is not None

        if item_type != "port":
            # For tools, check directories
            c_base = Path(cfg.sdk_root) / item_id
            h_base = Path(cfg.dev_root) / item_id
            c_inst = c_base.exists()
            h_inst = h_base.exists()
            if item_id == "kos":
                c_inst = (c_base / "environ.sh").exists()
                h_inst = (h_base / "environ.sh").exists()

        # Active detection
        state_file = cfg.state_dir / f"{item_id}_dev"
        is_host_active = state_file.exists()

        # Source Detection
        c_ports_dir = cfg.get_tool_dir("kos-ports", force_mode="0")
        h_ports_dir = cfg.get_tool_dir("kos-ports", force_mode="1")

        # Check for 'dist' folder which indicates 'make fetch' was run
        c_source = (c_ports_dir / item_id / "dist").exists()
        h_source = (h_ports_dir / item_id / "dist").exists()

        return {
            "c_inst": "o" if c_inst else ("c" if c_source and item_type == "port" else "x"),
            "h_inst": "o" if h_inst else ("c" if h_source and item_type == "port" else "x"),
            "c_active": not is_host_active,
            "h_active": is_host_active
        }
