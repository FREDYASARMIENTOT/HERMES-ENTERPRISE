import re
lines = open(r'd:\HERMES-ENTERPRISE\tools\Crear-HermesProyecto.ps1','r',encoding='utf-8').readlines()
matches = [(i+1,l.rstrip('\r\n')) for i,l in enumerate(lines) if l.strip()=='"@' and i+1<194]
print(f"Found {len(matches)} here-string closings before line 194:")
for m in matches:
    print(f"  Line {m[0]}: {repr(m[1])}")