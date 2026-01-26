from typing import List, Tuple
from services.ui import UI
from services.status import StatusService
from core.config import cfg
from core.manifest import ManifestParser, Manifest

class Presenter:
    @staticmethod
    def print_legend() -> None:
        l_inst = f"{UI.GREEN}[✓]{UI.RESET}=Installed"
        l_actv = f"{UI.YELLOW}[*]{UI.RESET}=Active"
        l_none = f"{UI.GRAY}[x]{UI.RESET}=Not"
        l_clon = f"{UI.BLUE}[S]{UI.RESET}=Source"
        l_fail = f"{UI.RED}[!]{UI.RESET}=Issue"

        print(f"{UI.BOLD}STATUS:{UI.RESET} {l_inst}  {l_actv}  {l_none}  {l_clon}  {l_fail}")
        print(f"{UI.BOLD}MODES:{UI.RESET}  {UI.B_CYAN}CONT{UI.RESET}:Container  {UI.B_CYAN}HOST{UI.RESET}:Host\n")

    @staticmethod
    def render_search_table(results: List[Manifest], filter_installed: bool = False) -> None:
        Presenter.print_legend()
        if not results:
            print(f"  {UI.GRAY}No matches found in Registry or KOS-PORTS.{UI.RESET}\n")
            return

        headers = [
            ("TYPE", 12, UI.B_CYAN),
            ("ID", 20, UI.B_CYAN),
            ("CONT", 4, UI.B_CYAN),
            ("HOST", 4, UI.B_CYAN),
            ("DESCRIPTION", 40, UI.B_CYAN)
        ]

        rows = []
        filtered_count = 0

        for m in results:
            status = StatusService.get_status_data(m.id, m.type)

            # Apply Installation Filter
            if filter_installed:
                # Show if installed in EITHER container OR host
                if status["c_inst"] == "x" and status["h_inst"] == "x":
                    continue

            c_pill = UI.status_pill(status["c_inst"], status["c_active"], active_color=UI.GREEN)
            h_pill = UI.status_pill(status["h_inst"], status["h_active"], active_color=UI.YELLOW)

            rows.append([
                (f"[{m.type.upper()}]", UI.CYAN),
                (m.id, UI.BLUE),
                (c_pill, ""),
                (h_pill, ""),
                (m.desc, UI.RESET)
            ])
            filtered_count += 1

        if filtered_count == 0 and filter_installed:
            print(f"  {UI.GRAY}No installed packages found matching query.{UI.RESET}\n")
            return

        # Explicitly typing rows for safety, though dynamic
        print(UI.render_table(headers, rows))

        # Help user if ports repo is missing
        if not cfg.kos_ports_dir.exists():
            print(f"  {UI.YELLOW}INFO: KOS-PORTS repository missing. Individual libraries (ports) are hidden.{UI.RESET}")
            print(f"  {UI.GRAY}Run 'kosaio clone kos-ports' to see available libraries.{UI.RESET}\n")

    @staticmethod
    def render_ports_table() -> None:
        ports_path = cfg.kos_ports_dir
        if not ports_path.exists():
            return

        skip_dirs = {"utils", "scripts", "include", "lib", "examples", "kos-ports"}
        ports = []
        for makefile in ports_path.glob("*/Makefile"):
            if makefile.parent.name in skip_dirs: continue
            ports.append(makefile.parent.name)
        ports.sort()

        headers = [
            ("LIBRARY", 20, UI.B_CYAN),
            ("CONT", 6, UI.B_CYAN),
            ("HOST", 6, UI.B_CYAN),
            ("DESCRIPTION", 40, UI.B_CYAN)
        ]

        rows = []
        for lib in ports:
            status = StatusService.get_status_data(lib, "port")
            c_pill = UI.status_pill(status["c_inst"], status["c_active"], active_color=UI.GREEN)
            h_pill = UI.status_pill(status["h_inst"], status["h_active"], active_color=UI.YELLOW)

            m = ManifestParser.parse_port_makefile(ports_path / lib / "Makefile")
            desc = m.desc if m else "No description"

            rows.append([
                (lib, UI.BLUE),
                (c_pill, ""),
                (h_pill, ""),
                (desc, UI.RESET)
            ])

        print(UI.render_table(headers, rows))

    @staticmethod
    def render_banner(branch: str, commit: str, date: str) -> None:
        """Renders a perfectly aligned HUD banner box."""
        width = 60
        
        # Border parts
        top = f"{UI.GRAY}  ┌" + ("─" * (width)) + "┐" + UI.RESET
        mid_sep = f"{UI.GRAY}  ├" + ("─" * (width)) + "┤" + UI.RESET
        bot = f"{UI.GRAY}  └" + ("─" * (width)) + "┘" + UI.RESET
        
        pipe = f"{UI.GRAY}│{UI.RESET}"
        
        # Line 1: Title and Versioning
        title = f"{UI.B_CYAN}KOSAIO{UI.RESET} {UI.CYAN}MASTER HUD{UI.RESET}"
        version = f"{UI.B_MAGENTA}{branch}{UI.RESET} {UI.GRAY}@{UI.RESET} {UI.MAGENTA}{commit[:7]}{UI.RESET} {UI.GRAY}({date}){UI.RESET}"
        
        vlen_1 = UI.strlen(title) + 2 + UI.strlen(version)
        pad_1 = " " * max(0, width - vlen_1 - 2)
        line_1 = f"  {pipe} {title}  {version}{pad_1} {pipe}"
        
        # Line 2 & 3: Modes (split for legibility)
        m_sys = f"{UI.GREEN}MODE{UI.RESET} [{UI.GREEN}SYS{UI.RESET}] {UI.GRAY}System/Container{UI.RESET} - Optimized environment"
        vlen_2 = UI.strlen(m_sys)
        pad_2 = " " * max(0, width - vlen_2 - 2)
        line_2 = f"  {pipe} {m_sys}{pad_2} {pipe}"

        m_dev = f"{UI.YELLOW}MODE{UI.RESET} [{UI.YELLOW}DEV{UI.RESET}] {UI.GRAY}Host/Workspace{UI.RESET}   - Developer workspace"
        vlen_3 = UI.strlen(m_dev)
        pad_3 = " " * max(0, width - vlen_3 - 2)
        line_3 = f"  {pipe} {m_dev}{pad_3} {pipe}"
        
        # Line 4: Help
        help_txt = f"{UI.B_CYAN}HELP{UI.RESET} Type {UI.YELLOW}kosaio{UI.RESET} to start discovery."
        vlen_4 = UI.strlen(help_txt)
        pad_4 = " " * max(0, width - vlen_4 - 2)
        line_4 = f"  {pipe} {help_txt}{pad_4} {pipe}"

        print(top)
        print(line_1)
        print(mid_sep)
        print(line_2)
        print(line_3)
        print(line_4)
        print(bot)
