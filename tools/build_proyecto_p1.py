#!/usr/bin/env python3
import os
OUT = r"d:\HERMES-ENTERPRISE\Hermes.Web\templates\proyecto.html"

P = []

P.append('<!DOCTYPE html>\n<html lang="es" data-bs-theme="dark">\n<head>\n<meta charset="UTF-8">\n<meta name="viewport" content="width=device-width,initial-scale=1.0">\n<title>Hermes Enterprise &mdash; Implementaci&oacute;n del Proyecto</title>\n')
P.append('<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">\n')
P.append('<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">\n')
P.append('<style>\n:root{--hermes-primary:#0d6efd;--hermes-accent:#6f42c1;--hermes-success:#198754;--hermes-warning:#ffc107;--hermes-danger:#dc3545}\n')
P.append('body{background:linear-gradient(135deg,#0a0a0f 0%,#1a1a2e 50%,#16213e 100%);min-height:100vh;font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}\n')
P.append('.navbar-brand{font-weight:700;font-size:1.5rem;background:linear-gradient(135deg,var(--hermes-primary),var(--hermes-accent));-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}\n')
P.append('.card{border:1px solid rgba(255,255,255,0.1);background:rgba(255,255,255,0.03);backdrop-filter:blur(10px)}\n')
P.append('.card-header{border-bottom:1px solid rgba(255,255,255,0.1);background:rgba(255,255,255,0.05)}\n')
P.append('.step-pass{border-left:4px solid var(--hermes-success)}\n.step-fail{border-left:4px solid var(--hermes-danger)}\n.step-progress{border-left:4px solid var(--hermes-warning)}\n.step-pending{border-left:4px solid rgba(255,255,255,0.2)}\n')
P.append('.status-badge{font-size:.7rem;padding:.2rem .5rem}\n')
P.append('.pipeline-line{position:relative;padding-left:30px}\n.pipeline-line::before{content:\'\';position:absolute;left:15px;top:0;bottom:0;width:2px;background:rgba(255,255,255,0.1)}\n')
P.append('.pipeline-dot{position:absolute;left:8px;width:16px;height:16px;border-radius:50%;z-index:1}\n.pipeline-dot.pass{background:var(--hermes-success);box-shadow:0 0 10px rgba(25,135,84,0.5)}\n')
P.append('.pipeline-dot.fail{background:var(--hermes-danger);box-shadow:0 0 10px rgba(220,53,69,0.5)}\n.pipeline-dot.progress{background:var(--hermes-warning);animation:pulse 1.5s infinite}\n')
P.append('.pipeline-dot.pending{background:rgba(255,255,255,0.2)}\n@keyframes pulse{0%,100%{opacity:1}50%{opacity:0.5}}\n@keyframes fadeIn{from{opacity:0;transform:translateY(-5px)}to{opacity:1;transform:translateY(0)}}\n')
P.append('.fade-in{animation:fadeIn .3s ease-out}\n.duration-text{font-size:.8rem;color:rgba(255,255,255,0.5);font-family:monospace}\n')
P.append('.auto-refresh-badge{position:fixed;bottom:20px;right:20px;z-index:1000}\n.section-icon{width:32px;height:32px;display:inline-flex;align-items:center;justify-content:center;border-radius:8px}\n')
P.append('.trace-table td{padding:.3rem .5rem}\n.trace-table tr:hover{background:rgba(255,255,255,0.03)}\n.vscode-btn{background:#007acc;color:#fff;border:none}\n.vscode-btn:hover{background:#005a9e;color:#fff}\n')
P.append('.result-pass{color:var(--hermes-success)}\n.result-fail{color:var(--hermes-danger)}\n.result-pending{color:var(--hermes-warning)}\n')
P.append('.event-info{background:rgba(13,110,253,0.08)}\n.event-pass{background:rgba(25,135,84,0.08)}\n.event-warn{background:rgba(255,193,7,0.08)}\n.event-error{background:rgba(220,53,69,0.08)}\n')
P.append('.global-success{background:linear-gradient(135deg,rgba(25,135,84,0.2),rgba(25,135,84,0.05));border:1px solid rgba(25,135,84,0.3)}\n')
P.append('.global-fail{background:linear-gradient(135deg,rgba(220,53,69,0.2),rgba(220,53,69,0.05));border:1px solid rgba(220,53,69,0.3)}\n')
P.append('.global-progress{background:linear-gradient(135deg,rgba(255,193,7,0.2),rgba(255,193,7,0.05));border:1px solid rgba(255,193,7,0.3)}\n')
P.append('.substep-row{background:rgba(255,255,255,0.02)}\n.substep-row:hover{background:rgba(255,255,255,0.05)}\n')
P.append('.filter-btn.active{border-color:var(--hermes-primary)!important}\n.event-detail-panel{background:rgba(0,0,0,0.3);border-radius:8px}\n')
P.append('.clickable{cursor:pointer}\n.clickable:hover{background:rgba(255,255,255,0.05)}\n')
P.append('.big-number{font-size:2.2rem;font-weight:800;line-height:1}\n.step-counter{font-size:.9rem;opacity:.8}\n')
P.append('.badge-info{background:rgba(13,110,253,0.2);color:#6ea8fe}\n.badge-pass{background:rgba(25,135,84,0.2);color:#75b798}\n.badge-warn{background:rgba(255,193,7,0.2);color:#ffda6a}\n.badge-error{background:rgba(220,53,69,0.2);color:#ea868f}\n')
P.append('</style>\n</head>\n<body>\n')

with open('tools/build_proyecto_1.pkl', 'w', encoding='utf-8') as f:
    for p in P:
        f.write(p)
print("Part 1 written")