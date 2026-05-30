import pytest
from services.ports import PortService

class TestPortNameSanitization:
    def test_safe_name_passes(self):
        assert PortService._sanitize_port_name("libpng") == "libpng"

    def test_empty_name_rejected(self):
        assert PortService._sanitize_port_name("") is None

    def test_dot_prefix_rejected(self):
        assert PortService._sanitize_port_name(".hidden") is None

    def test_path_traversal_rejected(self):
        assert PortService._sanitize_port_name("../../etc/passwd") is None

    def test_absolute_path_rejected(self):
        assert PortService._sanitize_port_name("/etc/passwd") is None

    def test_name_with_slash_rejected(self):
        assert PortService._sanitize_port_name("foo/bar") is None

    def test_dotdot_name_rejected(self):
        assert PortService._sanitize_port_name("..") is None
