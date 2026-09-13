"""
bootstrap_portal.py — Bootstrap module for Azure App Service (AS-HermesPortal)

=== PROBLEM ===
The deployment directory is named "Hermes.Web/" (with a literal dot). When uvicorn
tries to import "Hermes.Web.backend.main:app", Python's default PathFinder cannot
match the dotted module path to a filesystem directory named "Hermes.Web/" because
Python splits "Hermes.Web" into package "Hermes" with submodule "Web".

A custom HermesWebFinder (inside main.py) solves this, but it can't be used to
import main.py itself — it's defined inside the very module being imported.

=== SOLUTION ===
This bootstrap loads main.py directly via importlib.util.spec_from_file_location,
bypassing Python's dotted-module resolution. Once main.py executes, its top-level
code registers the HermesWebFinder, which then handles all subsequent Hermes.Web.*
imports within main.py.

=== USAGE ===
    uvicorn bootstrap_portal:app --host 0.0.0.0 --port 8000 --workers 1
"""

import os
import sys
import importlib.util
from pathlib import Path

APP_ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(APP_ROOT))

# Path to the actual main module inside Hermes.Web/
MAIN_MODULE_PATH = APP_ROOT / 'Hermes.Web' / 'backend' / 'main.py'

if not MAIN_MODULE_PATH.exists():
    raise ImportError(
        f"Cannot find Hermes.Web backend main module at: {MAIN_MODULE_PATH}\n"
        f"Contents of {APP_ROOT}: {list(APP_ROOT.iterdir())}"
    )

# Use importlib to load the module directly from file path,
# bypassing Python's dotted-path resolution
spec = importlib.util.spec_from_file_location(
    'Hermes.Web.backend.main',
    str(MAIN_MODULE_PATH)
)
if spec is None:
    raise ImportError(
        f"Failed to create module spec for: {MAIN_MODULE_PATH}"
    )

module = importlib.util.module_from_spec(spec)
sys.modules['Hermes.Web.backend.main'] = module

# This executes main.py, which:
#   1. Adds project root to sys.path
#   2. Defines and registers HermesWebFinder in sys.meta_path
#   3. Imports servicio_fabrica (now AFTER finder registration ✓)
#   4. Creates the FastAPI app
spec.loader.exec_module(module)

# Expose the FastAPI app for uvicorn
app = module.app