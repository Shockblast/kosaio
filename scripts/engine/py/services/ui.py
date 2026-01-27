import re
from typing import List, Tuple, Union, Any

class UI:
    # ANSI Colors
    RESET = "\033[0m"
    BOLD = "\033[1m"
    CYAN = "\033[0;36m"
    B_CYAN = "\033[1;36m"
    BLUE = "\033[1;34m"
    GREEN = "\033[1;32m"
    YELLOW = "\033[1;33m"
    RED = "\033[1;31m"
    MAGENTA = "\033[0;35m"
    B_MAGENTA = "\033[1;35m"
    GRAY = "\033[0;90m"

    @staticmethod
    def visual_len(s: str) -> int:
        """Visible length of string accounting for ANSI, emojis, and variation selectors."""
        import unicodedata
        # Remove ANSI escape sequences
        clean = re.sub(r'\033\[[0-9;]*[a-zA-Z]', '', s)
        vlen = 0
        for char in clean:
            # Skip non-spacing marks (like variation selectors \ufe0f)
            if unicodedata.category(char) == 'Mn':
                continue
            # Most emojis and CJK characters have east_asian_width 'W', 'F' or 'A'
            # In modern terminals, Ambiguous ('A') is usually 2 columns.
            if unicodedata.east_asian_width(char) in ('W', 'F', 'A'):
                vlen += 2
            else:
                vlen += 1
        return vlen

    @staticmethod
    def strlen(s: str) -> int:
        """Alias for visual_len for backwards compatibility."""
        return UI.visual_len(s)

    @staticmethod
    def pad(s: str, width: int) -> str:
        """Pads string to visible width."""
        vlen = UI.visual_len(s)
        padding = " " * max(0, width - vlen)
        return f"{s}{padding}"

    @staticmethod
    def truncate(s: str, width: int) -> str:
        """Truncates string to visible width."""
        vlen = UI.visual_len(s)
        if vlen > width:
            return s[:width-3] + "..."
        return s

    @staticmethod
    def render_alert_box(title: str, lines: List[str], width: int = 66) -> str:
        """Draws a visually striking alert box with centered icons."""
        is_urgent = any(word in title.upper() for word in ["AGRESSIVE", "WARNING", "URGENT", "ERROR", "CRITICAL"])
        color = UI.RED if is_urgent else UI.YELLOW
        
        # Premium emoji pair: Warning + Lightning
        icon_l = "⚠️  ⚡ " # for some reason, looks good this way (maybe my fonts?)
        icon_r = " ⚡⚠️" # for some reason, looks good this way (maybe my fonts?)
        full_title = f"{icon_l}{title}{icon_r}"
        
        output = []
        # Upper Border: ┌─────┐
        output.append(f"\n{color}\u250c" + "\u2500" * (width) + f"\u2510{UI.RESET}")
        
        # Header (Centered)
        vlen_title = UI.visual_len(full_title)
        padding_total = width - vlen_title - 2
        padding_l = padding_total // 2
        padding_r = padding_total - padding_l
        
        output.append(f"{color}\u2502{UI.RESET} " + (" " * padding_l) + f"{UI.BOLD}{color}{full_title}{UI.RESET}" + (" " * padding_r) + f" {color}\u2502{UI.RESET}")
        
        # Separator: ├─────┤
        output.append(f"{color}\u251c" + "\u2500" * (width) + f"\u2524{UI.RESET}")
        
        # Body
        for line in lines:
            vlen_line = UI.visual_len(line)
            padding_right = " " * max(0, width - vlen_line - 2)
            output.append(f"{color}\u2502{UI.RESET} {line} {padding_right}{color}\u2502{UI.RESET}")
            
        # Bottom Border: └─────┘
        output.append(f"{color}\u2514" + "\u2500" * (width) + f"\u2518{UI.RESET}\n")
        
        return "\n".join(output)

    @staticmethod
    def status_pill(installed: Union[str, bool], is_active: bool, active_color: str = YELLOW) -> str:
        char = "x"
        color = UI.GRAY

        if installed == "o" or installed is True:
            char = "✓"
            color = UI.GREEN
            if is_active: color = active_color
        elif installed == "c":
            char = "S" # Source available
            color = UI.BLUE
        elif installed == "!":
            char = "!"
            color = UI.RED

        m_char = "*" if is_active else " "
        return f"{color}[{char}{m_char}]{UI.RESET}"

    @staticmethod
    def render_table(headers: List[Tuple[str, int, str]], rows: List[List[Tuple[Any, str]]]) -> str:
        """
        headers: List of (label, width, color)
        rows: List of lists of (value, color)
        """
        # Header
        header_line = ""
        sep_line = ""
        for i, (label, width, color) in enumerate(headers):
            header_line += color + UI.pad(label, width) + UI.RESET
            sep_line += UI.GRAY + ("-" * width) + UI.RESET
            if i < len(headers) - 1:
                header_line += " | "
                sep_line += "-+-"

        output = [header_line, sep_line]

        # Rows
        for row in rows:
            row_line = ""
            for i, (val, color) in enumerate(row):
                # Ensure val is string
                val = str(val)
                width = headers[i][1]

                # Truncate if too long (visible)
                if UI.strlen(val) > width:
                    val = UI.truncate(val, width)

                row_line += color + UI.pad(val, width) + UI.RESET
                if i < len(row) - 1:
                    row_line += " | "
            output.append(row_line)

        return "\n".join(output)

