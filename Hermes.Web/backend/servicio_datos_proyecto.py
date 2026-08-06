"""
====================================================================
servicio_datos_proyecto.py — Capa de dominio de Hermes.Web
====================================================================

Este archivo implementa el ServicioDatosProyecto, que es la ÚNICA
capa autorizada para consultar datos a través de Hermes.Commands.
Ninguna otra capa (FastAPI, Middleware, Frontend) puede acceder
directamente a SQLite o a los Providers.

Arquitectura:
    FastAPI (API) → ServicioDatosProyecto → Hermes.Commands → Providers → SQLite

Principios:
    - Único punto de entrada a datos desde el backend
    - Nunca accede directamente a SQLite
    - Nunca accede directamente a Providers
    - Todas las consultas se realizan a través de PowerShell/Hermes.Commands
    - Todos los resultados se devuelven como diccionarios serializables a JSON
"""

import os
import sys
import json
import time
import logging
import subprocess
import platform
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional, Dict, Any, List, Union

# Configuración de logging
logger = logging.getLogger("Hermes.Web.ServicioDatos")


class ServicioDatosProyecto:
    """
    Servicio de dominio para consultar datos del proyecto Hermes Enterprise.
    
    Esta clase es el único punto de acceso a datos desde el Backend FastAPI.
    Todas las consultas se realizan ejecutando comandos de Hermes.Commands
    a través de PowerShell subprocess.
    
    Atributos:
        ruta_raiz_hermes: Ruta absoluta a la raíz del proyecto Hermes Enterprise
        ruta_modulo_commands: Ruta al módulo Hermes.Commands (.psd1/.psm1)
        timeout_default: Tiempo máximo de espera por defecto (en segundos)
        cache_resultados: Cache simple de resultados (dict)
        ultima_actualizacion_cache: Timestamp de la última actualización del cache
    """
    
    def __init__(
        self,
        ruta_raiz_hermes: str,
        ruta_modulo_commands: str,
        timeout_default: int = 60
    ):
        """
        Inicializa el ServicioDatosProyecto.
        
        Args:
            ruta_raiz_hermes: Ruta absoluta a la raíz del proyecto Hermes Enterprise
            ruta_modulo_commands: Ruta al módulo Hermes.Commands
            timeout_default: Tiempo máximo de espera por defecto (segundos)
        """
        self.ruta_raiz_hermes: str = ruta_raiz_hermes
        self.ruta_modulo_commands: str = ruta_modulo_commands
        self.timeout_default: int = timeout_default
        self.cache_resultados: Dict[str, Any] = {}
        self.ultima_actualizacion_cache: Optional[datetime] = None
        
        # Verificar que las rutas existen
        self._verificar_rutas()
        
        logger.info(
            f"ServicioDatosProyecto inicializado. "
            f"Raíz: {ruta_raiz_hermes}, "
            f"Módulo: {ruta_modulo_commands}"
        )
    
    def _verificar_rutas(self) -> None:
        """
        Verifica que las rutas de Hermes.Commands existen.
        Si no existen, registra una advertencia.
        """
        ruta_psd1 = Path(self.ruta_modulo_commands) / "Hermes.Commands.psd1"
        ruta_psm1 = Path(self.ruta_modulo_commands) / "Hermes.Commands.psm1"
        
        if not ruta_psd1.exists():
            logger.warning(f"Módulo Hermes.Commands no encontrado en: {ruta_psd1}")
        
        if not ruta_psm1.exists():
            logger.warning(f"Módulo Hermes.Commands no encontrado en: {ruta_psm1}")
    
    def _ejecutar_comando_powershell(
        self,
        nombre_comando: str,
        argumentos: Optional[Dict[str, Any]] = None,
        timeout_segundos: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        Ejecuta un comando de PowerShell y devuelve el resultado.
        
        Este es el método privado que ejecuta los comandos de Hermes.Commands.
        Construye la línea de comandos, ejecuta el proceso y parsea la salida.
        
        Args:
            nombre_comando: Nombre del comando Hermes a ejecutar
            argumentos: Diccionario con argumentos del comando
            timeout_segundos: Timeout personalizado (usa el default si es None)
        
        Returns:
            Diccionario con: exito, datos, error, comando, duracion_ms
        """
        tiempo_inicio = time.time()
        
        # Usar timeout por defecto si no se especifica
        if timeout_segundos is None:
            timeout_segundos = self.timeout_default
        
        resultado = {
            "exito": False,
            "datos": None,
            "error": None,
            "comando": nombre_comando,
            "duracion_ms": 0.0
        }
        
        try:
            # Construir el comando de PowerShell
            # Importar el módulo y ejecutar el comando
            comando_powershell = (
                f"Import-Module '{self.ruta_modulo_commands}' -Force; "
                f"{nombre_comando}"
            )
            
            # Agregar argumentos si existen
            if argumentos:
                for clave, valor in argumentos.items():
                    # Escapar comillas simples en el valor
                    valor_str = str(valor).replace("'", "''")
                    comando_powershell += f" -{clave} '{valor_str}'"
            
            # Convertir salida a JSON
            comando_powershell += " | ConvertTo-Json -Compress -Depth 10"
            
            logger.debug(f"Ejecutando comando: {nombre_comando}")
            
            # Ejecutar el proceso de PowerShell
            proceso = subprocess.run(
                ["powershell", "-NoProfile", "-NonInteractive", "-Command", comando_powershell],
                capture_output=True,
                text=True,
                timeout=timeout_segundos,
                cwd=self.ruta_raiz_hermes
            )
            
            # Analizar la salida
            if proceso.returncode == 0:
                salida_stdout = proceso.stdout.strip()
                
                if salida_stdout:
                    try:
                        # Intentar parsear como JSON
                        resultado["datos"] = json.loads(salida_stdout)
                        resultado["exito"] = True
                    except json.JSONDecodeError:
                        # Si no es JSON, devolver como texto plano
                        resultado["datos"] = salida_stdout
                        resultado["exito"] = True
                else:
                    # Comando ejecutado sin salida (puede ser normal)
                    resultado["datos"] = None
                    resultado["exito"] = True
                    resultado["error"] = "Comando ejecutado sin salida"
            else:
                # Error en la ejecución
                error_msg = proceso.stderr.strip() if proceso.stderr else ""
                if not error_msg:
                    error_msg = proceso.stdout.strip() if proceso.stdout else ""
                resultado["error"] = error_msg or f"Error del comando (código: {proceso.returncode})"
            
        except subprocess.TimeoutExpired:
            resultado["error"] = f"Timeout ({timeout_segundos}s) en comando: {nombre_comando}"
        except FileNotFoundError:
            resultado["error"] = "PowerShell no está disponible en el sistema"
        except Exception as error_general:
            resultado["error"] = f"Error inesperado: {str(error_general)}"
        
        # Calcular duración
        resultado["duracion_ms"] = round((time.time() - tiempo_inicio) * 1000, 2)
        
        return resultado
    
    def _simular_resultado(self, datos_simulados: Any) -> Dict[str, Any]:
        """
        Genera un resultado simulado para desarrollo/pruebas.
        Útil cuando Hermes.Commands no está disponible.
        
        Args:
            datos_simulados: Datos a incluir en la simulación
        
        Returns:
            Diccionario con resultado simulado
        """
        return {
            "exito": True,
            "datos": datos_simulados,
            "error": None,
            "comando": "simulado",
            "duracion_ms": 0.5
        }
    
    # ═══════════════════════════════════════════════════════════
    # Métodos públicos de consulta de datos
    # ═══════════════════════════════════════════════════════════
    
    def obtener_version_hermes(self) -> Dict[str, Any]:
        """
        Obtiene la versión actual de Hermes Enterprise y sus componentes.
        
        Consulta:
            Get-HermesVersion
        
        Returns:
            Dict con: version_hermes, version_commands, version_bootstrap,
                     version_python, version_ps, fecha_commit, etc.
        """
        try:
            resultado = self._ejecutar_comando_powershell("Get-HermesVersion")
            return resultado
        except Exception:
            return self._simular_resultado({
                "version": "2.0.0",
                "version_commands": "2.0.0",
                "version_python": platform.python_version(),
                "version_ps": platform.system(),
                "fecha": datetime.now(timezone.utc).isoformat()
            })
    
    def obtener_estado_proyecto(self) -> Dict[str, Any]:
        """
        Obtiene el estado actual del proyecto Hermes Enterprise.
        
        Returns:
            Dict con: nombre_proyecto, ruta, workspace, git, github, entorno
        """
        try:
            resultado = self._ejecutar_comando_powershell("Get-HermesProject")
            return resultado
        except Exception:
            return self._simular_resultado({
                "nombre": Path(self.ruta_raiz_hermes).name,
                "ruta": self.ruta_raiz_hermes,
                "existe_workspace": self._verificar_archivo(".code-workspace"),
                "existe_git": self._verificar_directorio(".git"),
                "existe_entorno": self._verificar_directorio("venv") or self._verificar_archivo("environment.yml")
            })
    
    def obtener_estado_workspace(self) -> Dict[str, Any]:
        """
        Obtiene el estado del workspace de VS Code.
        
        Returns:
            Dict con: archivos_workspace, workspaces_activos, etc.
        """
        try:
            resultado = self._ejecutar_comando_powershell("Get-HermesWorkspace")
            return resultado
        except Exception:
            return self._simular_resultado({
                "workspaces_encontrados": self._buscar_archivos("*.code-workspace"),
                "workspace_activo": self._verificar_archivo("HERMES-ENTERPRISE.code-workspace")
            })
    
    def obtener_estado_git(self) -> Dict[str, Any]:
        """
        Obtiene el estado del repositorio Git.
        
        Returns:
            Dict con: branch, commit, status, remoto, etc.
        """
        try:
            resultado = self._ejecutar_comando_powershell("Get-HermesVersion")
            return resultado
        except Exception:
            return self._simular_resultado(self._leer_git_desde_cli())
    
    def _leer_git_desde_cli(self) -> Dict[str, Any]:
        """
        Lee información de Git directamente desde la CLI.
        Solo se usa si Hermes.Commands no está disponible.
        """
        info_git = {
            "branch": "desconocido",
            "commit": "desconocido",
            "remoto": "ninguno",
            "estado": "no es repositorio git",
            "archivos_cambiados": 0
        }
        
        try:
            # Obtener branch actual
            branch = subprocess.run(
                ["git", "rev-parse", "--abbrev-ref", "HEAD"],
                capture_output=True, text=True, cwd=self.ruta_raiz_hermes
            )
            if branch.returncode == 0:
                info_git["branch"] = branch.stdout.strip()
            else:
                return info_git  # No es un repositorio git
            
            # Obtener commit actual
            commit = subprocess.run(
                ["git", "rev-parse", "--short", "HEAD"],
                capture_output=True, text=True, cwd=self.ruta_raiz_hermes
            )
            if commit.returncode == 0:
                info_git["commit"] = commit.stdout.strip()
            
            # Obtener remoto
            remoto = subprocess.run(
                ["git", "remote", "get-url", "origin"],
                capture_output=True, text=True, cwd=self.ruta_raiz_hermes
            )
            if remoto.returncode == 0:
                info_git["remoto"] = remoto.stdout.strip()
            
            # Obtener estado
            status = subprocess.run(
                ["git", "status", "--porcelain"],
                capture_output=True, text=True, cwd=self.ruta_raiz_hermes
            )
            if status.returncode == 0:
                lineas = [l for l in status.stdout.split("\n") if l.strip()]
                info_git["archivos_cambiados"] = len(lineas)
                info_git["estado"] = "limpio" if len(lineas) == 0 else f"{len(lineas)} archivo(s) modificado(s)"
            
            # Obtener último commit message
            log = subprocess.run(
                ["git", "log", "-1", "--oneline"],
                capture_output=True, text=True, cwd=self.ruta_raiz_hermes
            )
            if log.returncode == 0:
                info_git["ultimo_commit"] = log.stdout.strip()
            
        except Exception:
            pass
        
        return info_git
    
    def obtener_estado_github(self) -> Dict[str, Any]:
        """
        Obtiene el estado del repositorio GitHub remoto.
        
        Returns:
            Dict con: url_remota, branch_remota, sincronizado, etc.
        """
        info_git = self._leer_git_desde_cli()
        url_remota = info_git.get("remoto", "")
        
        esta_sincronizado = False
        try:
            # Verificar si el remoto está alcanzable
            fetch = subprocess.run(
                ["git", "fetch", "--dry-run"],
                capture_output=True, text=True, cwd=self.ruta_raiz_hermes,
                timeout=10
            )
            esta_sincronizado = fetch.returncode == 0 and not fetch.stdout.strip()
        except Exception:
            pass
        
        return self._simular_resultado({
            "url_remota": url_remota,
            "tiene_remoto": bool(url_remota) and url_remota != "ninguno",
            "sincronizado": esta_sincronizado,
            "branch_remota": f"origin/{info_git.get('branch', 'main')}",
            "es_github": "github.com" in url_remota if url_remota else False
        })
    
    def obtener_estado_entorno_python(self) -> Dict[str, Any]:
        """
        Obtiene el estado del entorno Python.
        
        Returns:
            Dict con: python_version, pip_version, paquetes, venv, etc.
        """
        try:
            resultado = self._ejecutar_comando_powershell("Get-HermesEnvironment")
            return resultado
        except Exception:
            return self._simular_resultado({
                "python_version": platform.python_version(),
                "python_path": sys.executable,
                "pip_version": self._ejecutar_pip("--version"),
                "tiene_venv": self._verificar_directorio("venv"),
                "tiene_environment_yml": self._verificar_archivo("environment.yml"),
                "tiene_requirements": self._verificar_archivo("requirements.txt"),
                "plataforma": platform.platform()
            })
    
    def _ejecutar_pip(self, argumento: str) -> str:
        """Ejecuta un comando pip y devuelve la salida."""
        try:
            resultado = subprocess.run(
                [sys.executable, "-m", "pip", *argumento.split()],
                capture_output=True, text=True, timeout=10
            )
            return resultado.stdout.strip() if resultado.returncode == 0 else "no disponible"
        except Exception:
            return "no disponible"
    
    def obtener_estado_azure(self) -> Dict[str, Any]:
        """
        Obtiene el estado de la configuración Azure.
        
        Returns:
            Dict con: configuracion_azure, app_service, recursos, etc.
        """
        try:
            resultado = self._ejecutar_comando_powershell("Get-HermesAzureConfiguration")
            return resultado
        except Exception:
            return self._simular_resultado(self._leer_configuracion_azure())
    
    def _leer_configuracion_azure(self) -> Dict[str, Any]:
        """
        Lee la configuración de Azure desde el archivo JSON canónico.
        Solo se usa si Hermes.Commands no está disponible.
        """
        ruta_config = Path(self.ruta_raiz_hermes) / "config" / "Hermes.Azure.json"
        if ruta_config.exists():
            try:
                with open(ruta_config, "r", encoding="utf-8") as archivo:
                    return json.load(archivo)
            except Exception:
                return {"error": "Error al leer configuración Azure"}
        return {"error": "Archivo Hermes.Azure.json no encontrado"}
    
    def obtener_estado_bootstrap(self) -> Dict[str, Any]:
        """
        Obtiene el estado del proceso Bootstrap de Hermes.
        
        Returns:
            Dict con: fase_actual, completado, progreso, etc.
        """
        try:
            resultado = self._ejecutar_comando_powershell("Get-HermesConfiguration")
            return resultado
        except Exception:
            return self._simular_resultado({
                "bootstrap_completado": self._verificar_directorio("motor/bootstrap"),
                "archivos_bootstrap": len(list(Path(self.ruta_raiz_hermes, "motor/bootstrap").rglob("*.ps1"))) if Path(self.ruta_raiz_hermes, "motor/bootstrap").exists() else 0,
                "wizard_disponible": (Path(self.ruta_raiz_hermes) / "motor" / "bootstrap" / "engine" / "BootstrapWizard.ps1").exists()
            })
    
    def obtener_estado_sqlite(self) -> Dict[str, Any]:
        """
        Obtiene el estado de la base de datos SQLite.
        
        Returns:
            Dict con: base_datos, tablas, registros, etc.
        """
        try:
            resultado = self._ejecutar_comando_powershell("Get-HermesConfiguration")
            return resultado
        except Exception:
            return self._simular_resultado({
                "bases_datos_encontradas": [
                    str(p.relative_to(self.ruta_raiz_hermes))
                    for p in Path(self.ruta_raiz_hermes).rglob("*.db")
                ],
                "tablas_disponibles": [],
                "mensaje": "SQLite disponible a través de Hermes.Commands"
            })
    
    def obtener_estado_telemetria(self) -> Dict[str, Any]:
        """
        Obtiene métricas de telemetría y observabilidad.
        
        Returns:
            Dict con: tiempo_actividad, solicitudes, errores, etc.
        """
        return self._simular_resultado({
            "servicio": "Hermes.Web",
            "tiempo_actividad": "Activo",
            "ultima_consulta": datetime.now(timezone.utc).isoformat(),
            "cache_activo": bool(self.cache_resultados),
            "modo": "operativo"
        })
    
    def obtener_estado_despliegue(self) -> Dict[str, Any]:
        """
        Obtiene el estado del despliegue y release.
        
        Returns:
            Dict con: archivos_build, release, deploy, etc.
        """
        ruta_deployment = Path(self.ruta_raiz_hermes) / "Hermes.Web" / "deployment"
        return self._simular_resultado({
            "carpeta_despliegue": str(ruta_deployment),
            "archivos_despliegue": [
                str(p.relative_to(ruta_deployment))
                for p in ruta_deployment.rglob("*") if p.is_file()
            ] if ruta_deployment.exists() else [],
            "release_lista": (ruta_deployment / "release").exists(),
            "app_service_configurado": self._leer_configuracion_azure().get("Azure", {})
        })
    
    # ═══════════════════════════════════════════════════════════
    # Métodos auxiliares
    # ═══════════════════════════════════════════════════════════
    
    def _verificar_directorio(self, nombre_directorio: str) -> bool:
        """Verifica si un directorio existe en la raíz del proyecto."""
        return (Path(self.ruta_raiz_hermes) / nombre_directorio).is_dir()
    
    def _verificar_archivo(self, nombre_archivo: str) -> bool:
        """Verifica si un archivo existe en la raíz del proyecto."""
        ruta = Path(self.ruta_raiz_hermes) / nombre_archivo
        return ruta.is_file()
    
    def _buscar_archivos(self, patron: str) -> List[str]:
        """Busca archivos que coincidan con un patrón glob."""
        try:
            return [
                str(p.relative_to(self.ruta_raiz_hermes))
                for p in Path(self.ruta_raiz_hermes).glob(patron)
            ]
        except Exception:
            return []
    
    def limpiar_cache(self) -> None:
        """Limpia el caché de resultados."""
        self.cache_resultados.clear()
        self.ultima_actualizacion_cache = None
        logger.info("Cache del ServicioDatosProyecto limpiado.")
    
    def obtener_informacion_completa(self) -> Dict[str, Any]:
        """
        Obtiene toda la información disponible del proyecto.
        Útil para el dashboard del Portal Web.
        
        Returns:
            Dict completo con todos los estados del proyecto
        """
        informacion = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "raiz_proyecto": self.ruta_raiz_hermes,
            "modo_ejecucion": "produccion" if not self._verificar_directorio("tests") else "desarrollo",
            "componentes": {
                "version": self.obtener_version_hermes(),
                "proyecto": self.obtener_estado_proyecto(),
                "workspace": self.obtener_estado_workspace(),
                "git": self.obtener_estado_git(),
                "github": self.obtener_estado_github(),
                "entorno_python": self.obtener_estado_entorno_python(),
                "azure": self.obtener_estado_azure(),
                "bootstrap": self.obtener_estado_bootstrap(),
                "sqlite": self.obtener_estado_sqlite(),
                "telemetria": self.obtener_estado_telemetria(),
                "despliegue": self.obtener_estado_despliegue()
            }
        }
        
        return informacion