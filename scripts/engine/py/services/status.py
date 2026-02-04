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
            holy_list = {"kos", "kos-ports", "sh-elf", "arm-eabi", "aicaos", "extras", "bin"}
            
            if item_id in holy_list:
                c_base = Path(cfg.sdk_root) / item_id
            else:
                c_base = Path(cfg.sdk_root) / "extras" / item_id
                
            h_base = Path(cfg.dev_root) / item_id
            
            c_inst = c_base.exists()
            h_inst = h_base.exists()
            if item_id == "kos":
                # KOS Specific: Check for compiled library for "Installed" status
                # Container
                c_env = c_base / "environ.sh"
                c_lib = c_base / "lib" / "dreamcast" / "libkallisti.a"
                
                if c_lib.exists():
                    c_inst = True # Installed
                elif c_base.exists():
                    c_inst = "c" # Source only (or uncompiled)
                else:
                    c_inst = False

                # Host
                h_env = h_base / "environ.sh"
                h_lib = h_base / "lib" / "dreamcast" / "libkallisti.a"
                
                if h_lib.exists():
                    h_inst = True
                elif h_base.exists():
                     h_inst = "c"
                else:
                    h_inst = False

            elif item_id == "aicaos":
                # AICAOS Specific: Check for compiled library
                # Note: AICAOS installs INTO the KOS addons directory
                
                # Resolve KOS Base for Container (System) and Host (Dev)
                # We can't rely on env vars here as we are scanning distinct modes
                
                # Container AICAOS Check
                kos_c = Path(cfg.sdk_root) / "kos"
                aica_lib_c = kos_c / "addons" / "lib" / "dreamcast" / "libaicaos.a"
                
                if aica_lib_c.exists():
                    c_inst = True
                elif c_base.exists():
                     c_inst = "c" # Source
                else:
                    c_inst = False
                    
                # Host AICAOS Check
                # Host mode usually assumes KOS is also in host mode, but it might not be.
                # However, if we are in Host mode for AICAOS, we look for source in dev_root.
                # The installation check is tricky because it installs to KOS_BASE.
                # We will check if it was 'applied' (source compiled) by checking artifacts in source?
                # Or just assume if it's in source, it's "Source".
                # To be "Installed", it must be in the KOS addons.
                # Simplified: If resolving for Host, we check if KOS Host has the lib?
                # Actually AICAOS installs into KOS_BASE. 
                # If KOS is in Host mode, AICAOS installs to Host KOS.
                # If KOS is in Container mode, AICAOS installs to Container KOS.
                # This dependency makes "Installed" status ambiguous without knowing KOS mode.
                # For now, let's treat "Installed" if we see the compiled artifacts *in the source folder* too?
                # manifest 'export' says it needs `arm/aicaos.drv` and `libaicaos.a` in tool_dir.
                
                h_drv = h_base / "arm" / "aicaos.drv"
                h_lib = h_base / "libaicaos.a"
                
                if h_drv.exists() and h_lib.exists():
                    h_inst = True # It's built in the source folder
                elif h_base.exists():
                    h_inst = "c"
                else:
                    h_inst = False

        # Active detection
        state_file = cfg.state_dir / f"{item_id}_dev"
        is_host_active = state_file.exists()
        
        # BROKEN State Detection
        # If active in Host mode, but folder missing -> BROKEN
        if is_host_active and h_inst == False:
            h_inst = "!" 

        # Source Detection (for Ports)
        if item_type == "port":
            c_ports_dir = cfg.get_tool_dir("kos-ports", force_mode="0")
            h_ports_dir = cfg.get_tool_dir("kos-ports", force_mode="1")

            # Check for 'dist' folder which indicates 'make fetch' was run
            c_source = (c_ports_dir / item_id / "dist").exists()
            h_source = (h_ports_dir / item_id / "dist").exists()
        else:
            c_source = False
            h_source = False

        return {
            "c_inst": "o" if c_inst is True else ("c" if c_inst == "c" or (c_source and item_type == "port") else "x"),
            "h_inst": "o" if h_inst is True else ("!" if h_inst == "!" else ("c" if h_inst == "c" or (h_source and item_type == "port") else "x")),
            "c_active": not is_host_active,
            "h_active": is_host_active
        }
