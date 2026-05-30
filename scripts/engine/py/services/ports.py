from pathlib import Path
from typing import List, Optional

from core.manifest import ManifestParser

class PortService:
    @staticmethod
    def resolve_bulk_dependencies(libs: List[str]) -> List[str]:
        resolved: List[str] = []

        def _resolve_recursive(lib_name: str):
            deps = ManifestParser.get_port_dependencies(lib_name)
            for dep in deps:
                if dep not in resolved:
                    _resolve_recursive(dep)
            if lib_name not in resolved:
                resolved.append(lib_name)

        for lib in libs:
            _resolve_recursive(lib)

        return resolved

    @staticmethod
    def _sanitize_port_name(name: str) -> Optional[str]:
        if not name or name.startswith("."):
            return None
        p = Path(name)
        if len(p.parts) != 1:
            return None
        return p.name

    @staticmethod
    def resolve_port_name(input_name: str) -> Optional[str]:
        """
        Case-insensitive port name resolution.
        Returns the canonical name if found, else None.
        """
        from core.config import cfg

        safe_name = PortService._sanitize_port_name(input_name)
        if safe_name is None:
            return None

        ports_dir = cfg.system_kos_ports_dir
        if not ports_dir.exists():
            return None

        # 1. Exact match check
        exact_path = ports_dir / safe_name / "Makefile"
        if exact_path.exists():
            return safe_name

        # 2. Case-insensitive search
        input_lower = safe_name.lower()
        for path in ports_dir.iterdir():
            if path.is_dir() and path.name.lower() == input_lower:
                if (path / "Makefile").exists():
                    return path.name

        return None

