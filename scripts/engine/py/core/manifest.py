import re
from pathlib import Path
from typing import Optional, List, Dict
from core.config import cfg

class Manifest:
    def __init__(self, item_id: str, name: str, desc: str, tags: str, item_type: str, path: str):
        self.id = item_id
        self.name = name
        self.desc = desc
        self.tags = tags
        self.type = item_type
        self.path = path

    def to_pipe_string(self) -> str:
        return f"{self.id}|{self.name}|{self.desc}|{self.tags}|{self.type}|{self.path}"

class ManifestParser:
    # Regex patterns for Registry (.sh files)
    REGISTRY_PATTERNS = {
        'id': re.compile(r'^[ \t]*ID="([^"]+)"', re.MULTILINE),
        'name': re.compile(r'^[ \t]*NAME="([^"]+)"', re.MULTILINE),
        'desc': re.compile(r'^[ \t]*DESC="([^"]+)"', re.MULTILINE),
        'tags': re.compile(r'^[ \t]*TAGS="([^"]+)"', re.MULTILINE),
        'type': re.compile(r'^[ \t]*TYPE="([^"]+)"', re.MULTILINE),
    }

    @staticmethod
    def parse_registry_file(path: Path) -> Optional[Manifest]:
        try:
            content = path.read_text(encoding='utf-8', errors='ignore')
        except Exception:
            return None

        data = {}
        for key, p in ManifestParser.REGISTRY_PATTERNS.items():
            match = p.search(content)
            data[key] = match.group(1) if match else ""

        if not data['id']:
            return None

        return Manifest(
            data['id'],
            data['name'],
            data['desc'].replace('|', ' '),
            data['tags'],
            data['type'],
            str(path)
        )

    @staticmethod
    def parse_port_makefile(path: Path) -> Optional[Manifest]:
        try:
            content = path.read_text(encoding='utf-8', errors='ignore')
            lib_name = path.parent.name

            # Extract info
            short_desc = "No description"
            match_desc = re.search(r'^SHORT_DESC\s*=\s*(.*)$', content, re.MULTILINE)
            if match_desc:
                short_desc = match_desc.group(1).strip().replace('|', ' ')

            # Extract more technical fields for updates
            version = "unknown"
            match_ver = re.search(r'^PORTVERSION\s*=\s*(.*)$', content, re.MULTILINE)
            if match_ver:
                version = match_ver.group(1).strip()
            
            repo = ""
            match_repo = re.search(r'^GIT_REPOSITORY\s*=\s*(.*)$', content, re.MULTILINE)
            if match_repo:
                repo = match_repo.group(1).strip()
            
            branch = ""
            match_branch = re.search(r'^GIT_BRANCH\s*=\s*(.*)$', content, re.MULTILINE)
            if match_branch:
                branch = match_branch.group(1).strip()

            m = Manifest(
                lib_name,
                lib_name,
                short_desc,
                "port,library",
                "port",
                str(path)
            )
            # Add extra fields (dynamically attached for now to avoid changing __init__ signature)
            m.version = version
            m.repo = repo
            m.branch = branch

            return m
        except Exception:
            return None

    @staticmethod
    def get_port_dependencies(lib_name: str) -> List[str]:
        makefile = cfg.kos_ports_dir / lib_name / "Makefile"
        if not makefile.exists():
            return []

        try:
            content = makefile.read_text(encoding='utf-8', errors='ignore')
            match = re.search(r'^DEPENDENCIES\s*=\s*(.*)$', content, re.MULTILINE)
            if match:
                return match.group(1).split('#')[0].split()
        except:
            pass
        return []

