lines = open(r'd:\HERMES-ENTERPRISE\tools\Crear-HermesProyecto.ps1','r',encoding='utf-8').readlines()
# Count " characters on each line, but ignore here-strings
in_heredoc = False
inside_func = False
for i, line in enumerate(lines, 1):
    stripped = line.strip()
    if stripped.startswith('function ') and stripped.endswith('{'):
        inside_func = True
        print(f"Line {i}: FUNC START: {stripped[:60]}")
    elif stripped == '}':
        if inside_func:
            print(f"Line {i}: FUNC END")
            inside_func = False
    
    # Track heredoc opens/closes
    if stripped.endswith('= @"'):
        in_heredoc = True
        print(f"Line {i}: HEREDOC OPEN: {stripped[:50]}")
    elif stripped == '"@' and in_heredoc:
        in_heredoc = False
        print(f"Line {i}: HEREDOC CLOSE")
    
    # If not in heredoc, count " 
    if not in_heredoc and i < 196:
        dq_count = line.count('"')
        if dq_count % 2 != 0:
            print(f"Line {i}: ODD QUOTES ({dq_count}): {stripped[:60]}")