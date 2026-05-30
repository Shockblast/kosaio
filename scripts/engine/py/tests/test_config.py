import os
import pytest
from pathlib import Path
from core.config import Config

class TestConfig:
    def test_defaults_when_no_env(self, monkeypatch):
        monkeypatch.delenv("KOSAIO_DIR", raising=False)
        monkeypatch.delenv("DREAMCAST_SDK", raising=False)
        monkeypatch.delenv("PROJECTS_DIR", raising=False)
        c = Config()
        assert c.kosaio_dir == "/opt/kosaio"
        assert c.sdk_root == "/opt/toolchains/dc"
        assert c.projects_root == "/opt/projects"

    def test_dev_root_uses_path_join(self):
        c = Config()
        assert c.dev_root == "/opt/projects/kosaio-dev"

    def test_get_tool_dir_container_mode(self):
        c = Config()
        c.dev_mode = "0"
        assert c.get_tool_dir("kos") == Path("/opt/toolchains/dc/kos")
        assert c.get_tool_dir("flycast") == Path("/opt/toolchains/dc/extras/flycast")

    def test_get_tool_dir_dev_mode(self):
        c = Config()
        c.dev_mode = "1"
        assert c.get_tool_dir("kos") == Path("/opt/projects/kosaio-dev/kos")

    def test_kos_ports_dir_property(self):
        c = Config()
        c.dev_mode = "0"
        assert c.kos_ports_dir == Path("/opt/toolchains/dc/kos-ports")
