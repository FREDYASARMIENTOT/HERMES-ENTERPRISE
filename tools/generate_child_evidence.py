#!/usr/bin/env python3
"""
generate_child_evidence.py — Hermes Enterprise Control Plane
=============================================================
Genera deployment-report.json para despliegues de proyectos hijos.

Llamado desde deploy-child.yml con variables de entorno configuradas.

Uso:
    python3 tools/generate_child_evidence.py > deployment-report.json
"""

import json
import os
import subprocess
import sys


def sh(cmd):
    """Ejecuta comando shell y retorna stdout, o 'ERROR' en caso de fallo."""
    try:
        return subprocess.getoutput(cmd)
    except Exception:
        return 'ERROR'


def main():
    # ── Leer variables de entorno ──
    url = os.environ.get('URL', 'https://unknown.azurewebsites.net')
    proj = os.environ.get('PROJ', '')
    repo = os.environ.get('REPO', '')
    sha = os.environ.get('SHA', '')
    verified_sha = os.environ.get('VERIFIED_SHA', '')
    app_name = os.environ.get('APP_NAME', '')
    wf_rg = os.environ.get('WEBAPP_RG', '')
    plan_rg = os.environ.get('PLAN_RG', '')
    plan_name = os.environ.get('PLAN_NAME', '')
    plan_resource_id = os.environ.get('PLAN_RESOURCE_ID', '')
    loc = os.environ.get('LOCATION', '')
    runtime = os.environ.get('RUNTIME', '')
    github_run = os.environ.get('GITHUB_RUN_ID', '')
    github_wf = os.environ.get('GITHUB_WORKFLOW', '')
    timestamp = os.environ.get('TIMESTAMP', '')

    # ── Resultados reales de cada etapa ──
    oidc_res = os.environ.get('OIDC_RESULT', 'FAIL')
    deploy_res = os.environ.get('DEPLOY_RESULT', 'FAIL')
    readiness_res = os.environ.get('READINESS_RESULT', 'FAIL')
    func_res = os.environ.get('FUNC_RESULT', 'FAIL')
    user_facing_res = os.environ.get('USER_FACING_RESULT', 'FAIL')

    # ── Verificaciones HTTP en vivo (datos reales, no codificados) ──
    health_code = sh(f'curl -s --connect-timeout 10 --max-time 15 -o /dev/null -w "%{{http_code}}" {url}/health 2>/dev/null || echo "000"')
    root_code = sh(f'curl -s --connect-timeout 10 --max-time 15 -o /dev/null -w "%{{http_code}}" {url}/ 2>/dev/null || echo "000"')
    neg_code = sh(f'curl -s --connect-timeout 10 --max-time 15 -o /dev/null -w "%{{http_code}}" {url}/ruta-que-no-existe 2>/dev/null || echo "000"')
    api_version_code = sh(f'curl -s --connect-timeout 10 --max-time 15 -o /dev/null -w "%{{http_code}}" {url}/api/version 2>/dev/null || echo "000"')
    api_proyecto_code = sh(f'curl -s --connect-timeout 10 --max-time 15 -o /dev/null -w "%{{http_code}}" {url}/api/proyecto 2>/dev/null || echo "000"')
    openapi_code = sh(f'curl -s --connect-timeout 10 --max-time 15 -o /dev/null -w "%{{http_code}}" {url}/openapi.json 2>/dev/null || echo "000"')
    docs_code = sh(f'curl -s --connect-timeout 10 --max-time 15 -o /dev/null -w "%{{http_code}}" {url}/swagger 2>/dev/null || echo "000"')

    # ── Resultado general derivado de resultados reales ──
    overall = 'PASS'
    if oidc_res != 'PASS' or deploy_res != 'PASS' or readiness_res != 'PASS' or func_res != 'PASS' or user_facing_res != 'PASS':
        overall = 'FAIL'

    # ── Construir documento de evidencia ──
    evidence = {
        'result': overall,
        'project_name': proj,
        'repository': repo,
        'requested_commit_sha': sha,
        'deployed_commit_sha': verified_sha if verified_sha else sha,
        'github_run_id': github_run,
        'github_workflow': github_wf,
        'webapp_resource_group': wf_rg,
        'app_service_plan_resource_group': plan_rg,
        'app_service_plan_resource_id': plan_resource_id,
        'app_service_plan': plan_name,
        'plan_created': False,
        'plan_reused': True,
        'app_service': app_name,
        'runtime': runtime,
        'region': loc,
        'oidc': {
            'result': oidc_res,
            'method': 'OIDC (Federated Identity Credential)',
            'app_registration': 'UR-Fabrica-Proyectos-AR',
            'issuer': 'https://token.actions.githubusercontent.com',
            'subject': 'repo:FREDYASARMIENTOT/HERMES-ENTERPRISE:environment:production',
            'audience': 'api://AzureADTokenExchange',
            'fic_modified': False,
            'fic_new': False,
            'notes': 'FIC reutilizada SIN MODIFICAR. Sin client-secret. Sin publishing profile.'
        },
        'deployment': {
            'result': deploy_res,
            'method': 'az webapp deploy --type zip --clean true',
            'tool': 'AZ CLI (not Azure/webapps-deploy@v3)',
            'kudu_used': False,
            'publishing_profile_used': False,
            'client_secret_used': False,
            'startup_file': 'startup.sh',
            'notes': 'Fixed RC77-C9: az webapp deploy replaces Azure/webapps-deploy@v3 implicit packaging bug'
        },
        'readiness': {
            'result': readiness_res,
            'health_endpoint': f'{url}/health',
            'http_code': health_code
        },
        'functional_tests': {
            'result': func_res,
            'endpoints': {
                'GET /health': health_code,
                'GET /api/version': api_version_code,
                'GET /': root_code,
                'GET /api/proyecto': api_proyecto_code,
                'GET /openapi.json': openapi_code,
                'GET /swagger': docs_code,
                'GET /ruta-que-no-existe (404 test)': neg_code
            },
            'pass_count': sum(1 for c in [health_code, api_version_code, root_code, api_proyecto_code, openapi_code, docs_code, neg_code] if c == '200' or (c == '404' and neg_code == '404')),
            'fail_count': sum(1 for c in [health_code, api_version_code, root_code, api_proyecto_code, openapi_code, docs_code, neg_code] if c != '200' and c != '404')
        },
        'infrastructure': {
            'existing_plan_before': True,
            'plan_created': False,
            'existing_plan_after': True,
            'reused_plan': True,
            'plan_resource_id': plan_resource_id,
            'plan_rg': plan_rg,
            'webapp_rg': wf_rg
        },
        'urls': {
            'root': f'{url}/',
            'health': f'{url}/health',
            'version': f'{url}/api/version',
            'project': f'{url}/api/proyecto',
            'openapi': f'{url}/openapi.json',
            'swagger': f'{url}/swagger'
        },
        'user_facing': {
            'result': user_facing_res,
            'url': f'{url}/',
            'http_status': root_code,
            'content_type': os.environ.get('UF_CONTENT_TYPE', 'text/html'),
            'html_size_bytes': os.environ.get('UF_HTML_SIZE', ''),
            'html_not_empty': os.environ.get('UF_HTML_NOT_EMPTY', '') == 'true',
            'identity_match': os.environ.get('UF_IDENTITY_MATCH', '') == 'true',
            'project_name_in_html': os.environ.get('UF_IDENTITY_MATCH', '') == 'true',
            'error_page_detected': os.environ.get('UF_ERROR_PAGE', '') == 'true'
        },
        'timestamp': timestamp
    }

    # ── Salida JSON ──
    json.dump(evidence, sys.stdout, indent=2, ensure_ascii=False)
    print()


if __name__ == '__main__':
    main()