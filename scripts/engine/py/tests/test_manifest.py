from pathlib import Path
from core.manifest import ManifestParser

SAMPLE_REGISTRY = """
ID="flycast"
NAME="Flycast Emulator"
DESC="A Sega Dreamcast/Naomi emulator with GDB support"
TAGS="emulator,dreamcast,naomi,gdb"
TYPE="emulator"
"""

SAMPLE_REGISTRY_WITH_PIPE = """
ID="testlib"
NAME="Test Library"
DESC="A library for rendering | and other things"
TAGS="lib,test"
TYPE="lib"
"""

class TestManifestParser:
    def test_parse_registry_file(self, tmp_path):
        mf = tmp_path / "flycast.sh"
        mf.write_text(SAMPLE_REGISTRY)
        m = ManifestParser.parse_registry_file(mf)
        assert m is not None
        assert m.id == "flycast"
        assert m.name == "Flycast Emulator"
        assert m.desc == "A Sega Dreamcast/Naomi emulator with GDB support"
        assert m.tags == "emulator,dreamcast,naomi,gdb"
        assert m.type == "emulator"

    def test_parse_registry_pipe_in_desc(self, tmp_path):
        mf = tmp_path / "testlib.sh"
        mf.write_text(SAMPLE_REGISTRY_WITH_PIPE)
        m = ManifestParser.parse_registry_file(mf)
        assert m is not None
        assert "|" not in m.desc, "Pipe should be sanitized from desc"
        assert "and other things" in m.desc

    def test_parse_empty_file(self, tmp_path):
        mf = tmp_path / "empty.sh"
        mf.write_text("")
        m = ManifestParser.parse_registry_file(mf)
        assert m is None

    def test_to_pipe_string_contains_no_extra_pipes(self, tmp_path):
        mf = tmp_path / "flycast.sh"
        mf.write_text(SAMPLE_REGISTRY)
        m = ManifestParser.parse_registry_file(mf)
        assert m is not None
        pipe = m.to_pipe_string()
        # id|name|desc|tags|type|path = 5 delimiters = 6 fields
        assert pipe.count("|") == 5
