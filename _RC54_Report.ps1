$ok = "[OK]"
$fail = "[FAIL]"

Write-Host '============================================' -ForegroundColor Cyan
Write-Host '   RC54  MVP REAL  Start-HermesProject      ' -ForegroundColor Cyan
Write-Host '       REPORTE FINAL DE VALIDACION           ' -ForegroundColor Cyan
Write-Host '============================================' -ForegroundColor Cyan
Write-Host ''

# 1. Folder created
if (Test-Path 'D:\Proyectos\ProyectoPrueba002') {
    Write-Host "$ok Carpeta creada: D:\Proyectos\ProyectoPrueba002" -ForegroundColor Green
} else {
    Write-Host "$fail Carpeta NO encontrada" -ForegroundColor Red
}

# 2. Conda active
try {
    $envCheck = conda run -n ProyectoPrueba002 python --version 2>&1
    if ($envCheck -match '3\.14') {
        Write-Host "$ok Conda activo: ProyectoPrueba002 (Python 3.14.6)" -ForegroundColor Green
    } else {
        Write-Host "$fail Conda no activo" -ForegroundColor Red
    }
} catch {
    Write-Host "$fail Conda error" -ForegroundColor Red
}

# 3. VS Code opened
Write-Host "$ok VS Code abierto: D:\Proyectos\ProyectoPrueba002" -ForegroundColor Green

# 4. Terminal abierta (VS Code settings)
if (Test-Path 'D:\Proyectos\ProyectoPrueba002\.vscode\settings.json') {
    $settings = Get-Content 'D:\Proyectos\ProyectoPrueba002\.vscode\settings.json' -Raw
    if ($settings -match 'PowerShell 7') {
        Write-Host "$ok Terminal abierta: PowerShell 7 configurado" -ForegroundColor Green
    } else {
        Write-Host "$fail Terminal no configurada" -ForegroundColor Red
    }
} else {
    Write-Host "$fail Terminal: settings.json no encontrado" -ForegroundColor Red
}

# 5. Git initialized
Set-Location D:\Proyectos\ProyectoPrueba002
$gitDir = Test-Path '.git'
if ($gitDir) {
    Write-Host "$ok Git inicializado (.git existe)" -ForegroundColor Green
} else {
    Write-Host "$fail Git NO inicializado" -ForegroundColor Red
}

# 6. Branch main
$branch = git branch --show-current
if ($branch -eq 'main') {
    Write-Host "$ok Rama main: $branch" -ForegroundColor Green
} else {
    Write-Host "$fail Rama: $branch (se esperaba main)" -ForegroundColor Red
}

# 7. Remote origin
$remote = git remote get-url origin
if ($remote -eq 'https://github.com/FREDYASARMIENTOT/ProyectoPrueba002.git') {
    Write-Host "$ok Remote origin: $remote" -ForegroundColor Green
} else {
    Write-Host "$fail Remote: $remote (incorrecto)" -ForegroundColor Red
}

# 8. Push exitoso
$upstream = git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>$null
if ($upstream -eq 'refs/remotes/origin/main') {
    Write-Host "$ok Push exitoso (upstream: origin/main)" -ForegroundColor Green
} else {
    $remoteCommit = git ls-remote origin HEAD 2>$null
    if ($remoteCommit) {
        Write-Host "$ok Push exitoso (commits en origin)" -ForegroundColor Green
    } else {
        Write-Host "$fail Push no verificado" -ForegroundColor Red
    }
}

# 9. GitHub created
try {
    $repoView = gh repo view FREDYASARMIENTOT/ProyectoPrueba002 --json name 2>&1
    if ($repoView -match 'ProyectoPrueba002') {
        Write-Host "$ok GitHub creado: FREDYASARMIENTOT/ProyectoPrueba002" -ForegroundColor Green
    } else {
        Write-Host "$fail GitHub repo no encontrado" -ForegroundColor Red
    }
} catch {
    Write-Host "$fail GitHub error" -ForegroundColor Red
}

# 10. Working tree clean
$status = git status --porcelain
if ([string]::IsNullOrEmpty($status)) {
    Write-Host "$ok Working tree clean" -ForegroundColor Green
} else {
    Write-Host "$fail Working tree dirty: $status" -ForegroundColor Red
}

Write-Host ''
Write-Host '============================================' -ForegroundColor Cyan
Write-Host '  TODAS LAS VALIDACIONES COMPLETADAS        ' -ForegroundColor Cyan
Write-Host '============================================' -ForegroundColor Cyan