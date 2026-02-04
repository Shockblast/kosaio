import sys
import os
from typing import List, Optional, Dict, Any

# Fix path to allow absolute imports within the package
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)

if parent_dir not in sys.path:
    sys.path.append(parent_dir)

from core.manifest import ManifestParser

class PortService:
    @staticmethod
    def resolve_bulk_dependencies(libs: List[str]) -> List[str]:
        """
        Resolves dependencies for a list of libraries, ensuring
        correct installation order and no duplicates.
        """
        resolved: List[str] = []

        def _resolve_recursive(lib_name: str):
            # If already resolved, skip (ensures we don't install twice)
            # NOTE: For topological sort, we might need to visit children first using a distinct visited set
            # vs the final resolved list. But here we assume a simple "install if not present" model.

            # Simple cycle detection/visited check could be added here if needed.
            # For now, we rely on the fact that if it's in resolved, we are good.
            # But wait, we want deps *before* the target.

            # 1. Get deps
            deps = ManifestParser.get_port_dependencies(lib_name)

            # 2. Process deps first
            for dep in deps:
                if dep not in resolved:
                    _resolve_recursive(dep)

            # 3. Add self if not already added
            if lib_name not in resolved:
                resolved.append(lib_name)

        for lib in libs:
            _resolve_recursive(lib)

        return resolved

    @staticmethod
    def get_port_info(lib_name: str) -> Dict[str, Any]:
        """
        Returns a dictionary with port metadata.
        """
        # We assume cfg is available or we can pass it,
        # but ManifestParser logic is what we really use.
        # Check core/config usage in main.py if needed.
        # For now, simplistic implementation mirroring main.py logic

        deps = ManifestParser.get_port_dependencies(lib_name)
        # In a real implementation we would parse the Makefile for Description/Version
        # Here we return what we can easily get.
        return {
            "name": lib_name,
            "dependencies": deps
        }

    @staticmethod
    def resolve_port_name(input_name: str) -> Optional[str]:
        """
        Case-insensitive port name resolution.
        Returns the canonical name if found, else None.
        """
        from core.config import cfg

        # 1. Exact match check
        exact_path = cfg.system_kos_ports_dir / input_name / "Makefile"
        if exact_path.exists():
            return input_name

        # 2. Case-insensitive search
        input_lower = input_name.lower()
        if cfg.system_kos_ports_dir.exists():
            for path in cfg.system_kos_ports_dir.iterdir():
                if path.is_dir() and path.name.lower() == input_lower:
                    if (path / "Makefile").exists():
                        return path.name

        return None

