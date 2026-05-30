from typing import List, Optional

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

