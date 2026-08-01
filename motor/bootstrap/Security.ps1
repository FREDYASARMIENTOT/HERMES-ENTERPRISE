# Security module (esqueleto) - incluye Test-GitSecrets
function Test-GitSecrets {
    param($RepoPath='.')
    # Simple scan: buscar archivos .env y patrones comunes en el historial
    $secretsFound = @()
    Get-ChildItem -Path $RepoPath -Recurse -Include '.env','.env.*' -ErrorAction SilentlyContinue | ForEach-Object {
        $text = Get-Content -Raw -Path $_.FullName
        if ($text -match 'AKIA[0-9A-Z]{16}|PRIVATE_KEY|SECRET|PASSWORD|TOKEN') { $secretsFound += $_.FullName }
    }
    # Historial: revisar commits recientes (Ãºltimos 50) por regex
    git log -n 50 --pretty=format:%H | ForEach-Object {
        $sha = $_
        $diff = git show $sha --pretty="" --name-only
        if ($diff -match '\.env|SECRET|PRIVATE_KEY|TOKEN') { $secretsFound += "commit:$sha" }
    }
    return ($secretsFound | Select-Object -Unique)
}

function Validate-PAT {
    # Comprueba que gh auth status funcione y que el token tenga al menos permisos bÃ¡sicos
    try {
        $status = gh auth status 2>&1
        if ($status -match 'Logged in to github.com') { return $true }
    } catch { # SuppressExpected }
    return $false
}
