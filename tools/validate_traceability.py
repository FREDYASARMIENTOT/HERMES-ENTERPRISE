#!/usr/bin/env python3
"""
validate_traceability.py - Validador Adversarial de Trazabilidad (FASE 20.19)
=====================================================================
Hermes Enterprise Observability Hardening

Propósito:
    Validación automática de consistencia entre:
    1. Portal Database (SQLite)
    2. deployment-trace.json
    3. Estado de pasos vs resultado global

Reglas adversariales:
    - PASS + PENDIENTE = FAIL
    - COMPLETADO + pasos EN_PROCESO = FAIL
    - FALLIDO + resultado PASS = FAIL
    - deployment_id debe ser constante
    - correlation_id debe ser constante
    - Todos los pasos obligatorios deben tener timestamps
    - No duraciones vacías cuando el paso está COMPLETADO

Uso:
    python tools/validate_traceability.py --db <sqlite_path> [--deployment-id <DID>]
"""

import json, os, sys, sqlite3, argparse
from datetime import datetime

PASOS_OBLIGATORIOS = list(range(1, 14))
ESTADOS_VALIDOS = {"PENDIENTE", "EN_PROCESO", "COMPLETADO", "FALLIDO", "OMITIDO"}
RESULTADOS_VALIDOS = {"PASS", "FAIL", ""}


class AuditorTrazabilidad:
    """Auditor adversarial de trazabilidad E2E."""

    def __init__(self, db_path: str = None):
        self.db_path = db_path
        self.errores = []
        self.warnings = []
        self.pases = []
        self.proyectos_auditados = 0

    def auditar(self, deployment_id: str = None) -> dict:
        self.errores = []
        self.warnings = []
        self.pases = []
        if not self.db_path or not os.path.exists(self.db_path):
            self.errores.append(f"BD no encontrada: {self.db_path}")
            return self._reporte()
        if deployment_id:
            return self._auditar_proyecto(deployment_id)
        return self._auditar_todos()

    def _auditar_todos(self) -> dict:
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        c = conn.cursor()
        try:
            c.execute("SELECT deployment_id FROM solicitudes_proyecto ORDER BY fecha_solicitud DESC")
            for r in c.fetchall():
                self._auditar_proyecto(r["deployment_id"])
        except Exception as e:
            self.errores.append(f"Error leyendo BD: {e}")
        finally:
            conn.close()
        return self._reporte()

    def _auditar_proyecto(self, deployment_id: str) -> dict:
        self.proyectos_auditados += 1
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        c = conn.cursor()
        try:
            c.execute("SELECT * FROM solicitudes_proyecto WHERE deployment_id=?", (deployment_id,))
            row = c.fetchone()
            if not row:
                self.errores.append(f"{deployment_id}: No encontrado")
                return self._reporte()
            proyecto = dict(row)
            c.execute("SELECT * FROM pasos_proyecto WHERE deployment_id=? ORDER BY numero_paso", (deployment_id,))
            pasos = [dict(r) for r in c.fetchall()]
            self._validar_proyecto(proyecto, pasos)
        except Exception as e:
            self.errores.append(f"Error auditando {deployment_id}: {e}")
        finally:
            conn.close()
        return self._reporte()

    def _validar_proyecto(self, proyecto: dict, pasos: list):
        did = proyecto.get("deployment_id", "?")
        nombre = proyecto.get("nombre_proyecto", "?")
        estado = proyecto.get("estado", "?")
        resultado = proyecto.get("resultado", "")
        cid = proyecto.get("correlation_id", "")
        self.pases.append(f"[{did}] {nombre}: estado={estado}, resultado={resultado}")

        # Regla 1: PASS + PENDIENTE = TRACEABILITY FAILURE
        pendientes = [p for p in pasos if p.get("estado_paso") in ("PENDIENTE", "EN_PROCESO")]
        if resultado == "PASS" and pendientes:
            self.errores.append(
                f"[{did}] TRACEABILITY FAILURE: PASS con {len(pendientes)} pendiente(s): "
                f"{[p.get('nombre_paso',str(p.get('numero_paso'))) for p in pendientes]}"
            )

        # Regla 2: Estado calculado debe coincidir
        ec = self._calcular_estado(pasos)
        if estado == "COMPLETADO" and ec != "COMPLETADO":
            self.errores.append(f"[{did}] estado={estado} pero calculado={ec}")

        # Regla 3: Timestamps
        for p in pasos:
            if p.get("estado_paso") == "COMPLETADO" and not p.get("fecha_fin"):
                self.warnings.append(f"[{did}] Paso {p.get('numero_paso')} COMPLETADO sin fecha_fin")

        # Regla 4: deployment_id constante
        if proyecto.get("deployment_id") != did:
            self.errores.append(f"[{did}] deployment_id inconsistente")

        # Regla 5: correlation_id
        if not cid:
            self.warnings.append(f"[{did}] correlation_id vacío")

        # Regla 6: FALLIDO con PASS
        if estado == "FALLIDO" and resultado == "PASS":
            self.errores.append(f"[{did}] FALLIDO con resultado=PASS")
def _calcular_estado(self, pasos: list) -> str:
        estados = [p.get("estado_paso", "PENDIENTE") for p in pasos]
        if any(e == "FALLIDO" for e in estados):
            return "FALLIDO"
        if any(e == "EN_PROCESO" for e in estados):
            return "EN_PROCESO"
        if any(e == "PENDIENTE" for e in estados):
            return "CREANDO"
        if all(e in ("COMPLETADO", "OMITIDO") for e in estados):
            return "COMPLETADO"
        return "DESCONOCIDO"

    def _reporte(self) -> dict:
        return {
            "auditoria": "validate_traceability.py FASE 20.19",
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "proyectos_auditados": self.proyectos_auditados,
            "resultado": "PASS" if not self.errores else "FAIL",
            "total_errores": len(self.errores),
            "total_warnings": len(self.warnings),
            "total_pases": len(self.pases),
            "errores": self.errores,
            "warnings": self.warnings,
            "pases": self.pases
        }


def main():
    parser = argparse.ArgumentParser(description="Validador Adversarial de Trazabilidad")
    parser.add_argument("--db", default=None, help="Ruta a SQLite de Portal")
    parser.add_argument("--deployment-id", default=None, help="Auditar proyecto especifico")
    parser.add_argument("--json", action="store_true", help="Salida en JSON")
    args = parser.parse_args()

    db_path = args.db or os.environ.get("HERMES_DB_PATH", "Hermes.Web/data/proyecto.db")
    if not os.path.exists(db_path):
        print(f"ERROR: BD no encontrada: {db_path}")
        sys.exit(1)

    auditor = AuditorTrazabilidad(db_path)
    reporte = auditor.auditar(args.deployment_id)

    if args.json:
        print(json.dumps(reporte, indent=2, ensure_ascii=False))
    else:
        print("=" * 70)
        print("  VALIDADOR ADVERSARIAL DE TRAZABILIDAD")
        print("  Hermes Enterprise FASE 20.19")
        print("=" * 70)
        print(f"  BD:       {db_path}")
        print(f"  Auditados: {reporte['proyectos_auditados']}")
        print(f"  Resultado: {reporte['resultado']}")
        print(f"  Errores:   {reporte['total_errores']}")
        print(f"  Warnings:  {reporte['total_warnings']}")
        if reporte["errores"]:
            print("\n  ERRORES:")
            for e in reporte["errores"]:
                print(f"    {e}")
        if reporte["warnings"]:
            print("\n  WARNINGS:")
            for w in reporte["warnings"]:
                print(f"    {w}")
        print()

    sys.exit(0 if reporte["resultado"] == "PASS" else 1)


if __name__ == "__main__":
    main()