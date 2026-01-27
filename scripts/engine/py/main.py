#!/usr/bin/env python3
"""
KOSAIO Python Engine - Single Source of Truth

This module provides the authoritative implementation for:
- Target validation and identification
- Path resolution for tools and manifests
- Dependency resolution for ports
- Search and discovery across registry and ports

Bash scripts in the engine/ directory delegate to this module
via CLI commands (e.g., `python3 main.py validate_target kos`).

Usage:
    python3 main.py <command> [args...]
    
Commands:
    search          - Search tools and ports
    validate_target - Validate a target and return its type
    get_tool_path   - Get resolved path for a tool
    get_manifest_path - Get path to manifest file
    resolve_deps    - Resolve port dependencies
    port_info       - Get port metadata
"""
import sys
import os
import argparse
from pathlib import Path

# Add the engine/py directory to sys.path to resolve core and services
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.append(current_dir)

from core.config import cfg
from core.manifest import ManifestParser
from services.searcher import SearchService
from services.resolver import DependencyResolver
from services.ui import UI
from services.status import StatusService
from services.presenter import Presenter
from services.ports import PortService
from services.validator import ValidatorService


# --- Handlers ---

def cmd_search(args):
    results = SearchService.search_all(args.query)
    Presenter.render_search_table(results, args.installed)

def cmd_update_cache(args):
    results = SearchService.search_all("")
    for m in results:
        print(m.to_pipe_string())

def cmd_list_ports(args):
    Presenter.render_ports_table()

def cmd_get_type(args):
    target_type = SearchService.identify_target(args.query)
    if target_type:
        print(target_type)
        sys.exit(0)
    sys.exit(1)

def cmd_deps(args):
    deps = DependencyResolver.resolve(args.query)
    print(" ".join(deps))

def cmd_resolve_deps(args):
    # args.query is a list because nargs='+'
    deps = PortService.resolve_bulk_dependencies(args.query)
    print(" ".join(deps))

def cmd_port_info(args):
    makefile = cfg.kos_ports_dir / args.query / "Makefile"
    if makefile.exists():
        m = ManifestParser.parse_port_makefile(makefile)
        if m:
            print(f"PORTNAME={m.id}")
            print(f"SHORT_DESC={m.desc}")
            print(f"PORTVERSION={getattr(m, 'version', 'unknown')}")
            print(f"GIT_REPOSITORY={getattr(m, 'repo', '')}")
            print(f"GIT_BRANCH={getattr(m, 'branch', '')}")
            print(f"DEPENDENCIES={' '.join(ManifestParser.get_port_dependencies(args.query))}")
            sys.exit(0)
    sys.exit(1)

def cmd_validate_target(args):
    """
    Validate a target and return its type.
    Output format: TYPE (on stdout)
    Errors: printed to stderr
    Exit codes: 0=valid, 1=not found, 3=dependency missing
    """
    result = ValidatorService.validate_target(args.target, args.action)

    if result.error:
        print(result.error, file=sys.stderr)

    if result.target_type:
        print(result.target_type)

    sys.exit(result.exit_code)

def cmd_get_tool_path(args):
    """
    Get the resolved path for a tool.
    This is the single source of truth for path resolution.
    """
    path = ValidatorService.get_tool_path(args.tool, args.mode)
    print(path)
    sys.exit(0)

def cmd_get_manifest_path(args):
    """
    Get the path to a manifest file for a tool.
    Returns the absolute path or exits with code 1 if not found.
    """
    path = SearchService.get_manifest_path(args.target)
    if path:
        print(path)
        sys.exit(0)
    else:
        print(f"Manifest not found for: {args.target}", file=sys.stderr)

        sys.exit(1)

def cmd_resolve_port_name(args):
    """
    Resolve a fuzzy/case-insensitive port name to its canonical name.
    """
    resolved = PortService.resolve_port_name(args.name)
    if resolved:
        print(resolved)
        sys.exit(0)
    else:
        # Don't print error to stdout to keep it clean for shell capture
        sys.exit(1)

def cmd_get_installed_ids(args):
    """
    Returns a space-separated list of all installed target IDs.
    """
    results = SearchService.search_all("")
    installed_ids = []
    for m in results:
        status = StatusService.get_status_data(m.id, m.type)
        if status["c_inst"] == "o" or status["h_inst"] == "o":
            installed_ids.append(m.id)
    print(" ".join(installed_ids))
    sys.exit(0)

def cmd_render_banner(args):
    """
    Renders the HUD banner with perfect alignment.
    """
    Presenter.render_banner(args.branch, args.commit, args.date)
    sys.exit(0)

def cmd_render_alert(args):
    """
    Renders a visually striking alert box.
    """
    print(UI.render_alert_box(args.title, args.lines))
    sys.exit(0)

# --- Main Dispatch ---

def main():
    parser = argparse.ArgumentParser(description="KOSAIO Engine")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Search Command
    p_search = subparsers.add_parser("search")
    p_search.add_argument("query", nargs="?", default="")
    p_search.add_argument("--installed", "-i", action="store_true")
    p_search.set_defaults(func=cmd_search)

    # Update Cache Command
    p_cache = subparsers.add_parser("update_cache")
    p_cache.set_defaults(func=cmd_update_cache)

    # List Ports Command
    p_list = subparsers.add_parser("list_ports")
    p_list.set_defaults(func=cmd_list_ports)

    # Get Type Command
    p_type = subparsers.add_parser("get_type")
    p_type.add_argument("query")
    p_type.set_defaults(func=cmd_get_type)

    # Deps Command (Legacy single)
    p_deps = subparsers.add_parser("deps")
    p_deps.add_argument("query")
    p_deps.set_defaults(func=cmd_deps)

    # Resolve Deps Command (Bulk)
    p_resolve = subparsers.add_parser("resolve_deps")
    p_resolve.add_argument("query", nargs="+")
    p_resolve.set_defaults(func=cmd_resolve_deps)

    # Port Info Command
    p_info = subparsers.add_parser("port_info")
    p_info.add_argument("query")
    p_info.set_defaults(func=cmd_port_info)

    # Validate Target Command (NEW - Single Source of Truth)
    p_validate = subparsers.add_parser("validate_target")
    p_validate.add_argument("target", help="Target ID to validate")
    p_validate.add_argument("--action", "-a", default=None, help="Action being performed (for context validation)")
    p_validate.set_defaults(func=cmd_validate_target)

    # Get Tool Path Command (NEW - Single Source of Truth)
    p_path = subparsers.add_parser("get_tool_path")
    p_path.add_argument("tool", help="Tool ID (e.g., kos, kos-ports, dcload-ip)")
    p_path.add_argument("--mode", "-m", choices=["dev", "sys"], default=None, help="Force dev or sys mode")
    p_path.set_defaults(func=cmd_get_tool_path)

    # Get Manifest Path Command (NEW - Single Source of Truth)
    p_manifest = subparsers.add_parser("get_manifest_path")
    p_manifest.add_argument("target", help="Target ID to find manifest for")
    p_manifest.set_defaults(func=cmd_get_manifest_path)


    # Resolve Port Name Command (NEW)
    p_resolve_name = subparsers.add_parser("resolve_port_name")
    p_resolve_name.add_argument("name", help="Port name to resolve")
    p_resolve_name.set_defaults(func=cmd_resolve_port_name)

    # Get Installed IDs Command
    p_inst_ids = subparsers.add_parser("get_installed_ids")
    p_inst_ids.set_defaults(func=cmd_get_installed_ids)

    # Render Banner Command (NEW)
    p_banner = subparsers.add_parser("render_banner")
    p_banner.add_argument("branch")
    p_banner.add_argument("commit")
    p_banner.add_argument("date")
    p_banner.set_defaults(func=cmd_render_banner)

    # Render Alert Command
    p_alert = subparsers.add_parser("render_alert")
    p_alert.add_argument("title")
    p_alert.add_argument("lines", nargs="+")
    p_alert.set_defaults(func=cmd_render_alert)

    # Parse args
    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)

    args = parser.parse_args()
    args.func(args)

if __name__ == "__main__":
    main()
