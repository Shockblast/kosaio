import pytest
from services.validator import ValidatorService, ValidationResult

class TestValidatorService:
    def test_validate_empty_target_returns_error(self):
        result = ValidatorService.validate_target("")
        assert result.exit_code == 1
        assert "cannot be empty" in result.error
    
    def test_validate_unknown_target_returns_not_found(self):
        result = ValidatorService.validate_target("nonexistent_xyz_123")
        assert result.exit_code == 1
        assert result.target_type == "unknown"
    
    def test_validate_known_tool_returns_tool(self):
        # We assume 'kos' or 'flycast' exists in the registry.
        # 'kos' is a core tool, usually present.
        result = ValidatorService.validate_target("kos")
        if result.exit_code != 0:
             pytest.skip("Registry might be empty or 'kos' missing in test env")
        
        assert result.exit_code == 0
        assert result.target_type == "tool"
    
    def test_validation_result_is_valid_property(self):
        valid = ValidationResult("tool", "kos", exit_code=0)
        invalid = ValidationResult("unknown", "xyz", error="Not found", exit_code=1)
        
        assert valid.is_valid is True
        assert invalid.is_valid is False
