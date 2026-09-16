import os
O = r"d:\HERMES-ENTERPRISE\Hermes.Web\templates\proyecto.html"
B = r"d:\HERMES-ENTERPRISE\tools"
parts = ["build_proyecto_1.pkl","build_proyecto_2.pkl","build_proyecto_3a.pkl","build_proyecto_3b.pkl","build_proyecto_3c.pkl","build_js1.pkl","build_js2.pkl","build_js3.pkl","build_js4a.pkl","build_js4b.pkl"]
t=0
with open(O,'w',encoding='utf-8') as f:
    for p in parts:
        pth = B+'\\'+p
        if not os.path.exists(pth):
            print("MISSING: "+pth); continue
        d=open(pth,'r',encoding='utf-8').read()
        f.write(d); t+=len(d)
        print(" + "+p+" ("+str(len(d))+" chars)")
if t>0:
    l=open(O,'r',encoding='utf-8').read().count('\n')
    print("OK: "+str(l)+" lines, "+str(os.path.getsize(O))+" bytes, "+str(t)+" chars")
