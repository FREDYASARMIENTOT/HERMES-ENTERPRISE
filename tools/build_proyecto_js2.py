#!/usr/bin/env python3
# JS Part 2 - renderDatos complete
J = r"""function renderDatos(data){if(!data)return;
var est=data.estado||'PENDIENTE';
var b=document.getElementById('estado-badge');b.textContent=est;b.className='badge status-badge';
if(est==='COMPLETADO')b.classList.add('bg-success');
else if(est==='FALLIDO')b.classList.add('bg-danger');
else if(['CREANDO','EN_PROCESO','SOLICITADO'].indexOf(est)>=0)b.classList.add('bg-warning','text-dark');
else b.classList.add('bg-secondary');
var c=document.getElementById('global-status-card');c.className='card mb-4';
if(est==='COMPLETADO')c.classList.add('global-success');
else if(est==='FALLIDO')c.classList.add('global-fail');
else c.classList.add('global-progress');
var el=document.getElementById('global-estado');el.textContent=est;el.className='big-number '+(est==='COMPLETADO'?'result-pass':est==='FALLIDO'?'result-fail':'result-pending');
var pasos=data.pasos||[];
var comp=0;for(var i=0;i<pasos.length;i++){if(pasos[i].estado==='COMPLETADO')comp++}
document.getElementById('steps-completed').textContent=comp+' / '+pasos.length;
var tSub=0,cSub=0;for(var i2=0;i2<pasos.length;i2++){var ss=pasos[i2].subpasos||[];for(var j=0;j<ss.length;j++){tSub++;if(ss[j].estado==='COMPLETADO'||ss[j].estado==='PASS')cSub++}}
document.getElementById('substeps-completed').textContent=tSub>0?cSub+' / '+tSub:'---';
document.getElementById('substeps-label').textContent=tSub>0?'SUBPASOS':'SIN SUBPASOS';
var cur=null;for(var i3=0;i3<pasos.length;i3++){if(pasos[i3].estado==='EN_PROCESO'){cur=pasos[i3];break}}
if(!cur){for(var i4=0;i4<pasos.length;i4++){if(pasos[i4].estado==='PENDIENTE'){cur=pasos[i4];break}}}
if(cur){document.getElementById('current-step-text').textContent='Paso actual: '+(cur.nombre||'Paso '+cur.numero);
var curSub=null;var css=cur.subpasos||[];for(var k=0;k<css.length;k++){if(css[k].estado==='EN_PROCESO'){curSub=css[k];break}}
document.getElementById('current-substep-text').textContent='Subpaso actual: '+(curSub?(curSub.nombre||'Subpaso'):'---');
}else{document.getElementById('current-step-text').textContent='Paso actual: ---';document.getElementById('current-substep-text').textContent='Subpaso actual: ---';}
document.getElementById('proj-name').textContent=data.nombre_proyecto||'---';
document.getElementById('proj-did').textContent=data.deployment_id||'---';
document.getElementById('proj-cid').textContent=data.correlation_id||'---';
document.getElementById('proj-resultado').textContent=data.resultado||'---';
document.getElementById('proj-inicio').textContent=formatTS(data.fecha_solicitud)||'---';
document.getElementById('proj-fin').textContent=formatTS(data.fecha_fin)||'---';
document.getElementById('proj-duracion').textContent=data.duracion_total_segundos?formatDuration(data.duracion_total_segundos):'---';
document.getElementById('proj-actualizacion').textContent=formatTS(data.fecha_actualizacion)||'---';
document.getElementById('total-duration-display').textContent=data.duracion_total_segundos?formatDuration(data.duracion_total_segundos):'---';
if(data.fecha_solicitud&&['COMPLETADO','FALLIDO'].indexOf(est)<0){var st=new Date(data.fecha_solicitud);var elp=Math.floor((Date.now()-st.getTime())/1000);document.getElementById('elapsed-time-text').textContent='Tiempo transcurrido: '+formatDuration(elp)}
else{document.getElementById('elapsed-time-text').textContent='Tiempo transcurrido: ---';}
renderTimeline(pasos);renderLinks(data);actualizarFiltros();}
"""

with open('tools/build_js2.pkl', 'w', encoding='utf-8') as f:
    f.write(J)
print("JS2 written, %d chars" % len(J))