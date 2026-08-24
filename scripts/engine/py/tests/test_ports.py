from services.ports import PortService
from core.config import cfg

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

class TestPortAliases:
    def _setup_ports_dir(self, tmp_path, monkeypatch):
        ports = tmp_path / "kos-ports"
        for lib, desc in (("libgl", "GLdc"), ("libal", "ALdc")):
            (ports / lib).mkdir(parents=True)
            (ports / lib / "Makefile").write_text(
                f"SHORT_DESC={desc}\nPORTVERSION=1.0\n"
            )
        monkeypatch.setattr(cfg, "kos_ports_dir_override", str(ports))
        return ports

    def test_gldc_alias_resolves_to_libgl(self, tmp_path, monkeypatch):
        self._setup_ports_dir(tmp_path, monkeypatch)
        assert PortService.resolve_port_name("gldc") == "libgl"

    def test_aldc_alias_resolves_to_libal(self, tmp_path, monkeypatch):
        self._setup_ports_dir(tmp_path, monkeypatch)
        assert PortService.resolve_port_name("aldc") == "libal"

    def test_alias_is_case_insensitive(self, tmp_path, monkeypatch):
        self._setup_ports_dir(tmp_path, monkeypatch)
        assert PortService.resolve_port_name("GLDC") == "libgl"

    def test_canonical_name_still_resolves(self, tmp_path, monkeypatch):
        self._setup_ports_dir(tmp_path, monkeypatch)
        assert PortService.resolve_port_name("libgl") == "libgl"

    def test_alias_not_found_returns_none(self, tmp_path, monkeypatch):
        self._setup_ports_dir(tmp_path, monkeypatch)
        assert PortService.resolve_port_name("unknown_alias") is None
