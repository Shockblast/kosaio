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
    def strlen(s: str) -> int:
        """Visible length of string (ignoring ANSI codes)."""
        return len(re.sub(r'\033\[[0-9;]*[a-zA-Z]', '', s))

    @staticmethod
    def pad(s: str, width: int) -> str:
        """Pads string to visible width."""
        vlen = UI.strlen(s)
        padding = " " * max(0, width - vlen)
        return f"{s}{padding}"

    @staticmethod
    def truncate(s: str, width: int) -> str:
        """Truncates string to visible width."""
        vlen = UI.strlen(s)
        if vlen > width:
            # Simplistic truncation (ignores potential internal ANSI for now)
            return s[:width-3] + "..."
        return s

    @staticmethod
    def status_pill(installed: Union[str, bool], is_active: bool) -> str:
        char = "x"
        color = UI.GRAY

        if installed == "o" or installed is True:
            char = "✓"
            color = UI.GREEN
            if is_active: color = UI.YELLOW
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

