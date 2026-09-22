#!/usr/bin/env python3
"""registro_implementacion.py - Registro de Implementacion para Hermes Enterprise."""

import json, sqlite3, uuid
from datetime import datetime
from typing import Optional

ESTADO_PENDIENTE = "PENDIENTE"
ESTADO_EN_PROCESO = "EN_PROCESO"
ESTADO_COMPLETADO = "COMPLETADO"
ESTADO_FALLIDO = "FALLIDO"
ESTADO_OMITIDO = "OMITIDO"
ESTADOS_VALIDOS = {ESTADO_PENDIENTE, ESTADO_EN_PROCESO, ESTADO_COMPLETADO, ESTADO_FALLIDO, ESTADO_OMITIDO}

PASOS_CANONICOS = [
    (1, "SOLICITUD", [("01.01","nombre del proyecto"),("01.02","repositorio"),("01.03","parametros")]),
    (2, "FACTORY", [("02.01","crear workspace"),("02.02","crear estructura"),("02.03","renderizar templates"),("02.04","validar placeholders"),("02.05","inicializar SQLite"),("02.06","registrar metadatos"),("02.07","inicializar Git")]),
    (3, "GITHUB", [("03.01","crear repositorio"),("03.02","configurar repositorio"),("03.03","publicar codigo"),("03.04","verificar branch"),("03.05","verificar SHA")]),
    (4, "CI CHILD", [("04.01","checkout"),("04.02","dependencias"),("04.03","validacion"),("04.04","resultado")]),
    (5, "CONTROL PLANE", [("05.01","recibir parametros"),("05.02","validar identidad"),("05.03","checkout Child"),("05.04","validar infraestructura")]),
    (6, "AUTENTICACION", [("06.01","GitHub OIDC"),("06.02","Azure login"),("06.03","comprobar resultado")]),
    (7, "AZURE", [("07.01","localizar ASP-IAUR"),("07.02","comprobar reutilizacion"),("07.03","crear/reutilizar Web App"),("07.04","configurar runtime"),("07.05","configurar startup")]),
    (8, "DEPLOY", [("08.01","construir ZIP"),("08.02","validar contenido ZIP"),("08.03","ZIP Deploy"),("08.04","reinicio"),("08.05","verificar SHA desplegado")]),
    (9, "READINESS", [("09.01","comprobar disponibilidad"),("09.02","comprobar HTTP"),("09.03","comprobar health"),("09.04","comprobar identidad")]),
    (10, "PRUEBAS FUNCIONALES", [("10.01","/"),("10.02","/health"),("10.03","/api/version"),("10.04","/api/proyecto"),("10.05","/openapi.json"),("10.06","/swagger"),("10.07","/redoc"),("10.08","endpoint inexistente 404")]),
    (11, "EVIDENCIA", [("11.01","requested SHA"),("11.02","deployed SHA"),("11.03","OIDC"),("11.04","deployment"),("11.05","readiness"),("11.06","functional tests"),("11.07","identidad"),("11.08","infraestructura")]),
    (12, "PUBLICACION", [("12.01","landing page"),("12.02","log de implementacion"),("12.03","accesos"),("12.04","estado final")]),
    (13, "NAVEGADOR", [("13.01","abrir /"),("13.02","abrir /health"),("13.03","abrir /api/version"),("13.04","abrir /api/proyecto"),("13.05","abrir /openapi.json"),("13.06","abrir /swagger"),("13.07","abrir /redoc")]),
]

def generar_id_despliegue():
    return uuid.uuid4().hex[:12].upper()

def calc_duracion(inicio, fin):
    if not inicio or not fin: return 0.0
    try:
        i = datetime.fromisoformat(inicio.replace('Z','+00:00'))
        f = datetime.fromisoformat(fin.replace('Z','+00:00'))
        return (f - i).total_seconds()
    except Exception:
        try:
            i = datetime.strptime(inicio.split('.')[0], '%Y-%m-%dT%H:%M:%S')
            f = datetime.strptime(fin.split('.')[0], '%Y-%m-%dT%H:%M:%S')
            return (f - i).total_seconds()
        except: return 0.0


class RegistroImplementacion:

    def __init__(self, ruta_sqlite="data/proyecto.db"):
        self.ruta_sqlite = ruta_sqlite
        self.imp = {"correlation_id":"","nombre_proyecto":"","repositorio":"",
            "commit_solicitado":"","commit_desplegado":"","deployment_id":"",
            "estado_general":ESTADO_PENDIENTE,"fecha_inicio":"","fecha_fin":"",
            "duracion_total_segundos":0,"pasos_completados":0,"pasos_fallidos":0,
            "pasos_totales":len(PASOS_CANONICOS)}
        self.pasos = []

    def iniciar_implementacion(self, nombre_proyecto, corr_id, repo="", sha="", dep_id=""):
        ahora = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.' + str(datetime.utcnow().microsecond // 1000).zfill(3) + 'Z')
        self.imp.update({"correlation_id":corr_id,"nombre_proyecto":nombre_proyecto,
            "repositorio":repo,"commit_solicitado":sha,"commit_desplegado":"",
            "deployment_id":dep_id or generar_id_despliegue(),
            "estado_general":ESTADO_EN_PROCESO,"fecha_inicio":ahora,"fecha_fin":"",
            "duracion_total_segundos":0,"pasos_completados":0,"pasos_fallidos":0})
        self.pasos = []
        for num, nom, subs in PASOS_CANONICOS:
            p = {"numero_paso":num,"nombre_paso":nom,"estado":ESTADO_PENDIENTE,
                "fecha_inicio":"","fecha_fin":"","duracion_segundos":0,
                "detalle":"","evidencia":"","resultado":"","subpasos":[]}
            for c, n in subs:
                p["subpasos"].append({"numero_subpaso":c,"nombre_subpaso":n,
                    "estado":ESTADO_PENDIENTE,"fecha_inicio":"","fecha_fin":"",
                    "duracion_segundos":0,"detalle":"","evidencia":"","resultado":""})
            self.pasos.append(p)
        return self

    def obtener_paso(self, n):
        for p in self.pasos:
            if p["numero_paso"] == n: return p
        return None

    def iniciar_paso(self, n, detalle=""):
        p = self.obtener_paso(n)
        if not p: return self
        a = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.' + str(datetime.utcnow().microsecond // 1000).zfill(3) + 'Z')
        p.update({"estado":ESTADO_EN_PROCESO,"fecha_inicio":a,"detalle":detalle}); return self

    def finalizar_paso(self, n, estado=ESTADO_COMPLETADO, detalle="", evidencia="", resultado=""):
        p = self.obtener_paso(n)
        if not p: return self
        a = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.' + str(datetime.utcnow().microsecond // 1000).zfill(3) + 'Z')
        p["estado"] = estado if estado in ESTADOS_VALIDOS else ESTADO_COMPLETADO
        p["fecha_fin"] = a; p["detalle"] = detalle or p["detalle"]; p["evidencia"] = evidencia
        p["resultado"] = resultado or ("PASS" if estado==ESTADO_COMPLETADO else "FAIL")
        if p["fecha_inicio"]: p["duracion_segundos"] = calc_duracion(p["fecha_inicio"], a)
        if estado==ESTADO_COMPLETADO: self.imp["pasos_completados"]+=1
        elif estado==ESTADO_FALLIDO: self.imp["pasos_fallidos"]+=1
        return self

    def iniciar_subpaso(self, np, ns, detalle=""):
        p = self.obtener_paso(np)
        if not p: return self
        a = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.' + str(datetime.utcnow().microsecond // 1000).zfill(3) + 'Z')
        for sp in p["subpasos"]:
            if sp["numero_subpaso"]==ns: sp.update({"estado":ESTADO_EN_PROCESO,"fecha_inicio":a,"detalle":detalle}); break
        return self

    def finalizar_subpaso(self, np, ns, estado=ESTADO_COMPLETADO, detalle="", evidencia="", resultado=""):
        p = self.obtener_paso(np)
        if not p: return self
        a = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.' + str(datetime.utcnow().microsecond // 1000).zfill(3) + 'Z')
        for sp in p["subpasos"]:
            if sp["numero_subpaso"]==ns:
                sp["estado"]=estado if estado in ESTADOS_VALIDOS else ESTADO_COMPLETADO
                sp["fecha_fin"]=a; sp["detalle"]=detalle or sp["detalle"]; sp["evidencia"]=evidencia
                sp["resultado"]=resultado or ("PASS" if estado==ESTADO_COMPLETADO else "FAIL")
                if sp["fecha_inicio"]: sp["duracion_segundos"]=calc_duracion(sp["fecha_inicio"],a)
                break
        return self

    def finalizar_implementacion(self, estado=ESTADO_COMPLETADO, detalle=""):
        a = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.' + str(datetime.utcnow().microsecond // 1000).zfill(3) + 'Z')
        self.imp["fecha_fin"] = a; self.imp["estado_general"] = estado
        if self.imp["fecha_inicio"]: self.imp["duracion_total_segundos"] = calc_duracion(self.imp["fecha_inicio"], a)
        if detalle: self.imp["detalle_final"] = detalle
        # Si el estado es FALLIDO, cascada a pasos PENDIENTE/EN_PROCESO
        if estado == ESTADO_FALLIDO:
            for p in self.pasos:
                if p["estado"] in (ESTADO_PENDIENTE, ESTADO_EN_PROCESO):
                    p["estado"] = ESTADO_FALLIDO
                    p["fecha_fin"] = a
                    if p.get("fecha_inicio"):
                        p["duracion_segundos"] = calc_duracion(p["fecha_inicio"], a)
                    p["resultado"] = "FAIL"
                    if not p.get("detalle"):
                        p["detalle"] = detalle or "Fallido por error en despliegue"
                # Marcar subpasos pendientes como FALLIDO
                if "subpasos" in p:
                    for sp in p["subpasos"]:
                        if sp["estado"] in (ESTADO_PENDIENTE, ESTADO_EN_PROCESO):
                            sp["estado"] = ESTADO_FALLIDO
                            sp["fecha_fin"] = a
                            sp["resultado"] = "FAIL"
            self.imp["pasos_fallidos"] = sum(1 for p in self.pasos if p["estado"] == ESTADO_FALLIDO)
        return self

    def _ensure_tables(self, c):
        """Crea las tablas de Implementacion si no existen (idempotente)."""
        c.execute("""CREATE TABLE IF NOT EXISTS Implementacion (
        Id INTEGER PRIMARY KEY AUTOINCREMENT,
        CorrelationId TEXT NOT NULL UNIQUE,
        NombreProyecto TEXT NOT NULL,
        Repositorio TEXT DEFAULT '',
        CommitSolicitado TEXT DEFAULT '',
        CommitDesplegado TEXT DEFAULT '',
        DeploymentId TEXT DEFAULT '',
        EstadoGeneral TEXT DEFAULT 'PENDIENTE',
        PasosCompletados INTEGER DEFAULT 0,
        PasosFallidos INTEGER DEFAULT 0,
        PasosTotales INTEGER DEFAULT 0,
        DuracionTotalSegundos REAL DEFAULT 0,
        FechaInicio TEXT,
        FechaFin TEXT)""")
        c.execute("""CREATE TABLE IF NOT EXISTS PasoImplementacion (
        Id INTEGER PRIMARY KEY AUTOINCREMENT,
        CorrelationId TEXT NOT NULL,
        NumeroPaso INTEGER NOT NULL,
        NombrePaso TEXT NOT NULL,
        NumeroSubpaso TEXT,
        NombreSubpaso TEXT,
        Estado TEXT DEFAULT 'PENDIENTE',
        FechaInicio TEXT,
        FechaFin TEXT,
        DuracionSegundos REAL DEFAULT 0,
        Detalle TEXT DEFAULT '',
        Evidencia TEXT DEFAULT '',
        Resultado TEXT DEFAULT '')""")
        try:
            c.execute("CREATE INDEX IF NOT EXISTS idx_paso_corr ON PasoImplementacion(CorrelationId)")
        except Exception:
            pass

    def persistir(self):
        if not self.ruta_sqlite or self.ruta_sqlite==":memory:": return False
        try:
            conn = sqlite3.connect(self.ruta_sqlite)
            c = conn.cursor()
            self._ensure_tables(c)
            i = self.imp
            c.execute('''INSERT INTO Implementacion (CorrelationId,NombreProyecto,Repositorio,
                CommitSolicitado,CommitDesplegado,DeploymentId,EstadoGeneral,
                PasosCompletados,PasosFallidos,PasosTotales,DuracionTotalSegundos,
                FechaInicio,FechaFin) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
                ON CONFLICT(CorrelationId) DO UPDATE SET
                EstadoGeneral=excluded.EstadoGeneral,
                PasosCompletados=excluded.PasosCompletados,
                PasosFallidos=excluded.PasosFallidos,
                DuracionTotalSegundos=excluded.DuracionTotalSegundos,
                FechaFin=excluded.FechaFin,
                CommitDesplegado=CASE WHEN excluded.CommitDesplegado!=''
                    THEN excluded.CommitDesplegado ELSE CommitDesplegado END''',
                (i["correlation_id"],i["nombre_proyecto"],i["repositorio"],
                 i["commit_solicitado"],i["commit_desplegado"],i["deployment_id"],
                 i["estado_general"],i["pasos_completados"],i["pasos_fallidos"],
                 i["pasos_totales"],i["duracion_total_segundos"],
                 i["fecha_inicio"],i["fecha_fin"]))
            c.execute("DELETE FROM PasoImplementacion WHERE CorrelationId=?",(i["correlation_id"],))
            for p in self.pasos:
                sj = json.dumps(p["subpasos"],ensure_ascii=False)
                c.execute('''INSERT INTO PasoImplementacion (CorrelationId,NumeroPaso,NombrePaso,
                    NumeroSubpaso,NombreSubpaso,Estado,FechaInicio,FechaFin,
                    DuracionSegundos,Detalle,Evidencia,Resultado) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)''',
                    (i["correlation_id"],p["numero_paso"],p["nombre_paso"],"","",
                     p["estado"],p["fecha_inicio"],p["fecha_fin"],
                     p["duracion_segundos"],sj,p["evidencia"],p["resultado"]))
            conn.commit(); conn.close(); return True
        except Exception as e:
            print(f"[RI] Error persist: {e}"); return False

    @staticmethod
    def obtener_desde_sqlite(ruta, corr_id):
        try:
            conn = sqlite3.connect(ruta)
            conn.row_factory = sqlite3.Row
            c = conn.cursor()
            c.execute("SELECT * FROM Implementacion WHERE CorrelationId=?",(corr_id,))
            imp = c.fetchone()
            if not imp: conn.close(); return None
            d = dict(imp)
            c.execute("SELECT * FROM PasoImplementacion WHERE CorrelationId=? ORDER BY NumeroPaso",(corr_id,))
            pasos = []
            for r in c.fetchall():
                p = dict(r)
                try: p["subpasos"] = json.loads(p["Detalle"]) if p.get("Detalle") else []
                except: p["subpasos"] = []
                pasos.append(p)
            d["pasos"] = pasos; conn.close(); return d
        except Exception as e:
            print(f"[RI] Error read: {e}"); return None

    def a_json(self):
        pjson = [{"numero":p["numero_paso"],"nombre":p["nombre_paso"],"estado":p["estado"],
            "fecha_inicio":p["fecha_inicio"],"fecha_fin":p["fecha_fin"],
            "duracion_segundos":p["duracion_segundos"],"detalle":p["detalle"],
            "evidencia":p["evidencia"],"resultado":p["resultado"],
            "subpasos":p["subpasos"]} for p in self.pasos]
        i = self.imp
        return {"proyecto":i["nombre_proyecto"],"repositorio":i["repositorio"],
            "correlation_id":i["correlation_id"],"deployment_id":i["deployment_id"],
            "commit_solicitado":i["commit_solicitado"],"commit_desplegado":i["commit_desplegado"],
            "estado_general":i["estado_general"],"fecha_inicio":i["fecha_inicio"],
            "fecha_fin":i["fecha_fin"],"duracion_total_segundos":i["duracion_total_segundos"],
            "pasos_completados":i["pasos_completados"],"pasos_fallidos":i["pasos_fallidos"],
            "pasos_totales":i["pasos_totales"],"pasos":pjson}


def main_cli():
    import sys
    a = sys.argv[1:]
    if len(a) < 2:
        print("Uso: registro_implementacion.py <db> <accion> [params]"); sys.exit(1)
    ruta, accion = a[0], a[1]
    reg = RegistroImplementacion(ruta)
    if accion == "iniciar":
        if len(a) < 4: print("Error: <db> iniciar <nombre> <corr_id>"); sys.exit(1)
        reg.iniciar_implementacion(a[2],a[3])
        if len(a)>4: reg.imp["repositorio"]=a[4]
        if len(a)>5: reg.imp["commit_solicitado"]=a[5]
        reg.persistir(); print(f"OK: {a[2]} ({a[3]})")
    elif accion in ("iniciar_paso","finalizar_paso"):
        if len(a) < 3: print("Error: params"); sys.exit(1)
        try:
            conn=sqlite3.connect(ruta);c=conn.cursor()
            c.execute("SELECT CorrelationId FROM Implementacion LIMIT 1")
            r=c.fetchone(); corr_id=r[0] if r else a[2]; conn.close()
        except: corr_id=a[2]
        reg.iniciar_implementacion("",corr_id)
        np=int(a[3]) if len(a)>3 else 1
        est=a[4] if len(a)>4 else ESTADO_COMPLETADO
        det=" ".join(a[5:]) if len(a)>5 else ""
        if accion=="iniciar_paso": reg.iniciar_paso(np,det)
        else: reg.iniciar_paso(np); reg.finalizar_paso(np,est,det)
        reg.persistir()
        print(f"OK: Paso {np} {accion.split('_')[0]}: {est}")
    else: print(f"Error: accion={accion}"); sys.exit(1)

if __name__=="__main__": main_cli()


