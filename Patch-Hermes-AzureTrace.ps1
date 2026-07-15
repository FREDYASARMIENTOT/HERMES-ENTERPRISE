# ===========================================================
# Patch-Hermes-AzureTrace.ps1
# Instrumenta Hermes CLI para mostrar exactamente
# qué envía al SDK OpenAI hacia Azure AI Foundry.
# ===========================================================

$File = "C:\Users\fredya.sarmiento\AppData\Local\hermes\hermes-agent\agent\chat_completion_helpers.py"

if (!(Test-Path $File))
{
    Write-Host ""
    Write-Host "ERROR:"
    Write-Host $File
    Write-Host "no existe."
    exit
}

Copy-Item $File "$File.original" -Force

$content = Get-Content $File -Raw

$Old = @'
    request_client = make_client("chat_completion_request")
    return request_client.chat.completions.create(**api_kwargs)
'@

$New = @'
    request_client = make_client("chat_completion_request")

    print("")
    print("="*90)
    print("AZURE FOUNDRY TRACE")
    print("="*90)

    try:
        print("CLIENT TYPE:", type(request_client))
    except Exception as e:
        print(e)

    try:
        print("BASE URL:", request_client.base_url)
    except Exception as e:
        print(e)

    try:
        print("DEFAULT QUERY:", request_client.default_query)
    except Exception as e:
        print(e)

    try:
        print("DEFAULT HEADERS:", request_client.default_headers)
    except Exception as e:
        print(e)

    try:
        print("MODEL:", api_kwargs.get("model"))
    except Exception as e:
        print(e)

    try:
        import pprint
        print("")
        print("API_KWARGS")
        pprint.pp(api_kwargs)
    except Exception as e:
        print(e)

    print("="*90)
    print("")

    return request_client.chat.completions.create(**api_kwargs)
'@

if($content.Contains($Old))
{
    $content = $content.Replace($Old,$New)
    Set-Content $File $content -Encoding UTF8

    Write-Host ""
    Write-Host "==============================================="
    Write-Host "PATCH INSTALADO"
    Write-Host "==============================================="
    Write-Host ""
    Write-Host "Backup:"
    Write-Host "$File.original"
}
else
{
    Write-Host ""
    Write-Host "No se encontró el bloque esperado."
    Write-Host "Hermes probablemente cambió."
}