#!/usr/bin/env python3
P = []
P.append('<script>\n')
P.append('var deploymentId=window.location.pathname.split(\'/\').pop();\n')
P.append('var refreshInterval=null,allEvents=[],projectData=null;\n')
P.append('var currentFilters={tipo:\'todos\',paso:\'todos\',componente:\'todos\',subpaso:\'todos\'};\n')
P.append('async function cargarDatos(){try{\n')
P.append('var r=await fetch(\'/api/fabrica/proyectos/\'+deploymentId);\n')
P.append('if(!r.ok)throw new Error(\'HTTP \'+r.status);\n')
P.append('projectData=await r.json();\n')
P.append('renderDatos(projectData);await cargarEventos();\n')
P.append('document.getElementById(\'loading-state\').classList.add(\'d-none\');\n')
P.append('document.getElementById(\'error-state\').classList.add(\'d-none\');\n')
P.append('document.getElementById(\'project-content\').classList.remove(\'d-none\');\n')
P.append('var est=projectData.estado||\'\';\n')
P.append('if([\'COMPLETADO\',\'FALLIDO\'].indexOf(est)>=0)detenerPolling();else iniciarPolling();\n')
P.append('}catch(e){console.error(e);\n')
P.append('document.getElementById(\'loading-state\').classList.add(\'d-none\');\n')
P.append('document.getElementById(\'error-state\').classList.remove(\'d-none\');\n')
P.append('document.getElementById(\'error-message\').textContent=e.message||\'Error desconocido\';}}\n')

with open('tools/build_js1.pkl', 'w', encoding='utf-8') as f:
    for p in P:
        f.write(p)
print("JS1 written")