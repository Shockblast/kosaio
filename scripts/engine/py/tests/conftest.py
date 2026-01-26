import pytest
import os
import sys
from pathlib import Path

@pytest.fixture(autouse=True)
def setup_env():
    """
    Ensure KOSAIO_DIR is set for tests and sys.path includes the app.
    """
    # 1. Calculate project root (assuming tests are in scripts/engine/py/tests)
    # File: scripts/engine/py/tests/conftest.py
    # Root: (up 4 levels) -> kosaio/
    test_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(test_dir))))
    
    # 2. Set KOSAIO_DIR if not present
    if "KOSAIO_DIR" not in os.environ:
        os.environ["KOSAIO_DIR"] = project_root

    # 3. Add 'scripts/engine/py' to sys.path so we can import 'core', 'services'
    engine_py_dir = os.path.dirname(test_dir)
    if engine_py_dir not in sys.path:
        sys.path.insert(0, engine_py_dir)
