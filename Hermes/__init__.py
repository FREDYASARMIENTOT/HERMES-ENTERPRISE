"""
Hermes — Paquete namespace raiz de Hermes Enterprise (RC63).

Este paquete permite que Hermes.Web sea importable usando:
    from Hermes.Web.backend.main import app

La resolucion se logra agregando la raiz del proyecto a sys.path,
lo que permite que Python encuentre el directorio ./Hermes.Web/ 
como un paquete de nivel superior.

Version: 2.0.0
"""
__version__ = "2.0.0"

import sys
import os
from pathlib import Path
import importlib.abc
import importlib.machinery

# ──────────────────────────────────────────────────────────────────────
# Sistema de carga para Hermes.Web (directorio con punto en el nombre)
# ──────────────────────────────────────────────────────────────────────
# Python no puede importar "Hermes.Web" como submodulo de "Hermes"
# porque el filesystem tiene Hermes.Web/ (un directorio con punto),
# no Hermes/Web/ (subdirectorio).
#
# Solucion: Registrar un MetaPathFinder que intercepta importaciones
# "Hermes.Web.xxx" y las resuelve desde ./Hermes.Web/xxx
# ──────────────────────────────────────────────────────────────────────

_HERMES_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_HERMES_WEB_DIR = Path(_HERMES_ROOT) / "Hermes.Web"

# Agregar raiz del proyecto a sys.path
if _HERMES_ROOT not in sys.path:
    sys.path.insert(0, _HERMES_ROOT)


class _HermesWebLoader(importlib.abc.Loader):
    """
    Loader manual para modulos Hermes.Web.
    Lee el archivo fuente, lo compila y lo ejecuta en el modulo,
    asegurando que __file__, __name__, __loader__ y __package__ esten
    correctamente definidos.
    """
    def __init__(self, fullname: str, path: Path, is_package: bool = False):
        self.fullname = fullname
        self.path = path
        self.is_package = is_package

    def create_module(self, spec):
        return None  # Usar semantica default de Python

    def exec_module(self, module):
        module.__file__ = str(self.path)
        module.__name__ = self.fullname
        module.__loader__ = self
        module.__package__ = ".".join(self.fullname.split(".")[:-1]) if not self.is_package else self.fullname

        with open(self.path, "rb") as f:
            source = f.read()
        code = compile(source, str(self.path), "exec", dont_inherit=True)
        exec(code, module.__dict__)


class _HermesWebFinder(importlib.abc.MetaPathFinder):
    """
    Finder que resuelve importaciones Hermes.Web.xxx
    mapeandolas al directorio ./Hermes.Web/xxx
    """
    def __init__(self, hermes_web_dir: Path):
        self._hermes_web_dir = hermes_web_dir
        self._prefix = "Hermes.Web"

    def find_spec(self, fullname, path=None, target=None):
        if not fullname.startswith(self._prefix):
            return None

        if fullname == self._prefix:
            # Paquete raiz Hermes.Web
            init_path = self._hermes_web_dir / "__init__.py"
            if init_path.exists():
                loader = _HermesWebLoader(fullname, init_path, is_package=True)
                spec = importlib.machinery.ModuleSpec(
                    fullname, loader, origin=str(init_path), is_package=True
                )
                spec.submodule_search_locations = [str(self._hermes_web_dir)]
                return spec
            return None

        # Submodulo: Hermes.Web.backend.main -> Hermes.Web/backend/main.py
        relative = fullname[len(self._prefix) + 1:]  # "backend.main"
        parts = relative.split(".")
        sub_path = self._hermes_web_dir.joinpath(*parts)

        # Probar como archivo .py
        py_file = sub_path.with_suffix(".py")
        if py_file.exists():
            loader = _HermesWebLoader(fullname, py_file)
            return importlib.machinery.ModuleSpec(
                fullname, loader, origin=str(py_file)
            )

        # Probar como paquete (directorio con __init__.py)
        init_file = sub_path / "__init__.py"
        if init_file.exists():
            loader = _HermesWebLoader(fullname, init_file, is_package=True)
            spec = importlib.machinery.ModuleSpec(
                fullname, loader, origin=str(init_file), is_package=True
            )
            spec.submodule_search_locations = [str(sub_path)]
            return spec

        return None


# Registrar el finder en sys.meta_path (PRIMERO en la lista)
if _HERMES_WEB_DIR.exists():
    sys.meta_path.insert(0, _HermesWebFinder(_HERMES_WEB_DIR))
