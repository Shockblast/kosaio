from pathlib import Path
from typing import List, Optional

from core.config import cfg
from core.manifest import ManifestParser, Manifest

class SearchService:
    @staticmethod
    def identify_target(target_id: str) -> Optional[str]:
        """
        Returns 'tool', 'port' or None by checking real directories.
        Supports aliases (e.g., sys -> system).
        """
        target_id = target_id.lower()
        if target_id == "sys": target_id = "system"
        if target_id == "kosaio": target_id = "self"

        # 1. Check Registry (Tools)
        registry_dir = cfg.registry_dir
        if registry_dir.exists():
            for manifest_path in registry_dir.rglob(f"{target_id}.sh"):
                return "tool"

        # 2. Check Diagnostics (Core/Internal)
        diag_dir = cfg.diagnostics_dir
        if diag_dir.exists():
             if (diag_dir / f"{target_id}.sh").exists():
                 return "core"

        # 3. Check Config (template-covered tool)
        if cfg.config_tools_dir.exists():
            if (cfg.config_tools_dir / f"{target_id}.conf").exists():
                return "tool"

        # 4. Check Ports
        # Use SYSTEM path for identification (Authoritative registry)
        ports_path = cfg.system_kos_ports_dir
        if ports_path.exists():
            # Exact match
            if (ports_path / target_id / "Makefile").exists():
                return "port"

            # Case-insensitive match
            for path in ports_path.iterdir():
                if path.is_dir() and path.name.lower() == target_id:
                    if (path / "Makefile").exists():
                        return "port"

        return None

    @staticmethod
    def get_manifest_path(target_id: str) -> Optional[Path]:
        """
        Returns the full path to a manifest file for a given target.
        Supports aliases (e.g., sys -> system).
        """
        target_id = target_id.lower()
        if target_id == "sys": target_id = "system"
        if target_id == "kosaio": target_id = "self"

        registry_dir = cfg.registry_dir
        if registry_dir.exists():
            for manifest_path in registry_dir.rglob(f"{target_id}.sh"):
                return manifest_path
        
        # Check Diagnostics
        diag_dir = cfg.diagnostics_dir
        if diag_dir.exists():
             diag_path = diag_dir / f"{target_id}.sh"
             if diag_path.exists():
                 return diag_path

        # Fallback to template if config exists
        if cfg.config_tools_dir.exists():
            if (cfg.config_tools_dir / f"{target_id}.conf").exists():
                if cfg.template_path.exists():
                    return cfg.template_path

        return None

    @staticmethod
    def search_all(query: str = "") -> List[Manifest]:
        """
        Search all available targets (registry tools and ports).
        
        Args:
            query: Search string. Empty string returns all results.
            
        Returns:
            List of Manifest objects matching the query, sorted by type priority.
        """
        results: List[Manifest] = []
        results.extend(SearchService.search_registry(query))
        results.extend(SearchService.search_ports(query))

        # Unique by ID
        seen = set()
        unique_results = []
        for r in results:
            if r.id not in seen:
                seen.add(r.id)
                unique_results.append(r)

        # Custom Sorting
        def type_priority(item: Manifest) -> int:
            t = item.type.lower()
            if t == "core": return 1
            if t == "tool": return 2
            if t == "lib": return 3
            if t == "emulator": return 4
            if t == "loader": return 5
            if t == "port": return 6
            return 99 # Rest

        unique_results.sort(key=lambda x: (type_priority(x), x.id))
        return unique_results

    @staticmethod
    def search_registry(query: str = "") -> List[Manifest]:
        query_lower = query.lower()
        results: List[Manifest] = []

        # 1. Search registry manifests
        if cfg.registry_dir.exists():
            for manifest_path in cfg.registry_dir.rglob("*.sh"):
                if manifest_path.name.endswith(".sample"):
                    continue
                if manifest_path.name == "process-standard.sh":
                    continue

                m = ManifestParser.parse_registry_file(manifest_path)
                if m:
                    if not query or any(query_lower in str(getattr(m, f)).lower() for f in ['id', 'name', 'desc', 'tags']):
                        results.append(m)

        # 2. Search config files for template-covered tools
        if cfg.config_tools_dir.exists():
            existing_ids = {m.id for m in results}
            for config_path in cfg.config_tools_dir.glob("*.conf"):
                tool_id = config_path.stem
                if tool_id not in existing_ids:
                    m = ManifestParser.parse_config_file(config_path)
                    if m:
                        if not query or any(query_lower in str(getattr(m, f)).lower() for f in ['id', 'name', 'desc', 'tags']):
                            results.append(m)

        return results

    @staticmethod
    def search_ports(query: str = "") -> List[Manifest]:
        # Always use SYSTEM path for search (Discovery should show all available)
        ports_path = cfg.system_kos_ports_dir
        if not ports_path or not ports_path.exists():
            return []

        import re
        q_lower = query.lower()
        regex_pattern = q_lower
        if not q_lower:
            regex_pattern = ".*"
        elif q_lower in ["opengl", "gl", "libgl", "3d", "graphics"]:
            regex_pattern = "(gl|kgl|parallax|tsunami|graphics)"
        elif q_lower in ["audio", "mp3", "sound", "music"]:
            regex_pattern = "(audio|tremor|sh4zam|vorbis|wav|mp3|ogg)"
        elif q_lower in ["network", "ip", "tcp"]:
            regex_pattern = "(network|lwip|tcp|ip)"

        compiled_regex = re.compile(regex_pattern, re.IGNORECASE)
        skip_dirs = {"utils", "scripts", "include", "lib", "examples", "kos-ports"}

        results: List[Manifest] = []
        for makefile in ports_path.glob("*/Makefile"):
            if makefile.parent.name in skip_dirs:
                continue

            m = ManifestParser.parse_port_makefile(makefile)
            if m:
                if compiled_regex.search(m.id) or compiled_regex.search(m.desc):
                    results.append(m)

        return results

