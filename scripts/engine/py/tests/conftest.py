import pytest
import os
import sys

# Calculate project root: scripts/engine/py/tests/conftest.py -> kosaio/
_test_dir = os.path.dirname(os.path.abspath(__file__))
_project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(_test_dir))))

# Ensure KOSAIO_DIR is set for tests
if "KOSAIO_DIR" not in os.environ:
    os.environ["KOSAIO_DIR"] = _project_root

# Add 'scripts/engine/py' to sys.path so imports from 'core', 'services' work
_engine_py_dir = os.path.dirname(_test_dir)
if _engine_py_dir not in sys.path:
    sys.path.insert(0, _engine_py_dir)


@pytest.fixture(autouse=True)
def setup_env():
    """Ensure environment is consistent for each test."""
    pass
