function Extract-Description {
    <#
    .SYNOPSIS
        Extrae la descripción de un archivo PowerShell desde su comentario .SYNOPSIS
    #>
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )
    
    if (-not (Test-Path $FilePath)) {
        return ""
    }
    
    $content = Get-Content $FilePath -Raw
    if ($content -match '(?s)\.SYNOPSIS\s*\r?\n(.+?)(\r?\n\r?\n|\r?\n\.)') {
        return $matches[1].Trim()
    }
    
    return ""
}

function Extract-Title {
    <#
    .SYNOPSIS
        Extrae el título de un archivo Markdown (primer H1)
    #>
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )
    
    if (-not (Test-Path $FilePath)) {
        return ""
    }
    
    $content = Get-Content $FilePath -Raw
    if ($content -match '(?m)^#\s+(.+)$') {
        return $matches[1].Trim()
    }
    
    return ""
}
