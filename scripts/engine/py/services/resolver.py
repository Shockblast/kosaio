import sys
import os
from typing import List, Optional

# Fix path to allow absolute imports within the package
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)

if parent_dir not in sys.path:
    sys.path.append(parent_dir)

from core.manifest import ManifestParser

class DependencyResolver:
    @staticmethod
    def resolve(lib_name: str, resolved_list: Optional[List[str]] = None) -> List[str]:
        if resolved_list is None:
            resolved_list = []

        deps = ManifestParser.get_port_dependencies(lib_name)
        for dep in deps:
            if dep not in resolved_list:
                # Recursive call
                DependencyResolver.resolve(dep, resolved_list)
                if dep not in resolved_list:
                    resolved_list.append(dep)

        return resolved_list

