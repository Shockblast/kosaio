"""
validator.py - Target Validation Service (Single Source of Truth)

Exit Codes:
    0: Valid target found
    1: Target not found
    2: Target found but action not supported
    3: Dependency missing (e.g., kos-ports not installed for port targets)
"""
import sys
from pathlib import Path

from core.config import cfg
from services.searcher import SearchService


class ValidationResult:
    """Structured result for target validation."""
    def __init__(self, target_type: str, target_id: str, error: str = None, exit_code: int = 0):
        self.target_type = target_type
        self.target_id = target_id
        self.error = error
        self.exit_code = exit_code

    @property
    def is_valid(self) -> bool:
        return self.exit_code == 0


class ValidatorService:
    """
    Centralized validation logic for KOSAIO targets.
    This is the SINGLE SOURCE OF TRUTH for target identification and validation.
    Bash scripts should call this instead of implementing their own logic.
    """

    # Actions that require kos-ports to be installed
    PORT_ACTIONS = {"install", "uninstall", "update", "build", "apply", "clean", "clone", "checkout", "reset"}

    @staticmethod
    def validate_target(target: str, action: str = None) -> ValidationResult:
        """
        Validate a target and determine its type.

        Args:
            target: The target identifier (e.g., 'kos', 'libpng', 'flycast')
            action: Optional action being performed (for context-aware validation)

        Returns:
            ValidationResult with target_type, or error information
        """
        if not target:
            return ValidationResult(
                target_type="",
                target_id="",
                error="Target cannot be empty",
                exit_code=1
            )

        target_lower = target.lower()

        # 1. Identify target type
        target_type = SearchService.identify_target(target_lower)

        if not target_type:
            return ValidationResult(
                target_type="unknown",
                target_id=target_lower,
                error=f"Target '{target}' not found in registry or ports",
                exit_code=1
            )

        # 2. Context-aware validation
        if target_type == "port" and action in ValidatorService.PORT_ACTIONS:
            if not cfg.kos_ports_dir.exists():
                return ValidationResult(
                    target_type=target_type,
                    target_id=target_lower,
                    error=f"Port '{target}' requires kos-ports. Run: kosaio clone kos-ports",
                    exit_code=3
                )

        # 3. Success
        return ValidationResult(
            target_type=target_type,
            target_id=target_lower,
            exit_code=0
        )

    @staticmethod
    def get_tool_path(tool: str, mode: str = None) -> Path:
        """
        Get the path for a tool based on dev mode settings.
        This consolidates logic that was duplicated in Bash env.sh and Python config.py.

        Args:
            tool: Tool identifier (e.g., 'kos', 'kos-ports', 'dcload-ip')
            mode: Optional forced mode ('dev', 'sys', or None for auto-detect)

        Returns:
            Path to the tool directory
        """
        force_mode = None
        if mode == "dev":
            force_mode = "1"
        elif mode == "sys":
            force_mode = "0"

        # Check if it's a port. Ports live INSIDE kos-ports.
        # We use a temporary config override if mode is provided to ensure identifying correctly
        target_type = SearchService.identify_target(tool)
        
        if target_type == "port":
            ports_dir = cfg.get_tool_dir("kos-ports", force_mode=force_mode)
            return ports_dir / tool

        return cfg.get_tool_dir(tool, force_mode=force_mode)
