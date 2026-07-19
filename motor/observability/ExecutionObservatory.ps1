# ExecutionObservatory.ps1
# Sidecar observer for Hermes bootstrap runs
param()

Import-Module -Name Microsoft.PowerShell.Management -ErrorAction SilentlyContinue

# Globals
$Execution:RunId = [guid]::NewGuid().ToString()
$Execution:StartTime = Get-Date
$Execution:LLMCalls = @()
$Execution:MaxRamMB = 0
$Execution:PeakCpu = 0
$Execution:Orphaned = 0
$Execution:Deadlock = @{ detected = $false; reason = '' }

function Start-Observatory {
    param([int]$PollIntervalMs = 500)
    $Execution:TargetPid = $PID
    Write-Host "[Observatory] starting (run_id=$($Execution:RunId))"
    $script:ObsTimer = New-Object System.Timers.Timer $PollIntervalMs
    $script:ObsTimer.AutoReset = $true
    $script:ObsTimer.Add_Elapsed({
        try {
            $proc = Get-Process -Id $Execution:TargetPid -ErrorAction SilentlyContinue
            if ($proc) {
                # RAM in MB
                $ram = [math]::Round($proc.WorkingSet64/1MB,2)
                if ($ram -gt $Execution:MaxRamMB) { $Execution:MaxRamMB = $ram }
                # CPU percent approximate via TotalProcessorTime delta
                $now = Get-Date
                if (-not $script:LastCpuSample) { $script:LastCpuSample = @{Time=$now; Cpu=$proc.TotalProcessorTime.TotalMilliseconds} }
                else {
                    $deltaMs = ($now - $script:LastCpuSample.Time).TotalMilliseconds
                    $deltaCpu = $proc.TotalProcessorTime.TotalMilliseconds - $script:LastCpuSample.Cpu
                    if ($deltaMs -gt 0) {
                        $cpuPct = [math]::Round((($deltaCpu / $deltaMs) / [Environment]::ProcessorCount) * 100,2)
                        if ($cpuPct -gt $Execution:PeakCpu) { $Execution:PeakCpu = $cpuPct }
                    }
                    $script:LastCpuSample = @{Time=$now; Cpu=$proc.TotalProcessorTime.TotalMilliseconds}
                }
                # child processes
                $children = Get-CimInstance Win32_Process -Filter "ParentProcessId=$($Execution:TargetPid)" -ErrorAction SilentlyContinue
                $script:LastChildren = $children
            } else {
                # process ended
                Stop-Observatory
            }
        } catch {
            # ignore
        }
    })
    $script:ObsTimer.Start()
}

function Register-LlmCall {
    param(
        [string]$Provider,
        [string]$Model,
        [int]$PromptTokens=0,
        [int]$CachedTokens=0,
        [int]$CompletionTokens=0,
        [double]$CostUsd=0.0,
        [int]$LatencyMs=0
    )
    $call = @{ provider=$Provider; model=$Model; prompt_tokens=$PromptTokens; cached_tokens=$CachedTokens; completion_tokens=$CompletionTokens; cost_usd=$CostUsd; latency_ms=$LatencyMs }
    $Execution:LLMCalls += $call
}

function Stop-Observatory {
    param()
    if ($script:ObsTimer) { $script:ObsTimer.Stop(); $script:ObsTimer.Dispose(); Remove-Variable -Name ObsTimer -Scope Script -ErrorAction SilentlyContinue }
    $Execution:EndTime = Get-Date
    # git state
    $git = @{ initial_commit=''; status='unknown' }
    try {
        if (Get-Command git -ErrorAction SilentlyContinue) {
            $cwd = Get-Location
            Push-Location $cwd
            $gitInitial = git rev-parse HEAD 2>$null
            if ($gitInitial) { $git.initial_commit = $gitInitial.Trim() }
            $status = git status --porcelain 2>$null
            $git.status = if ([string]::IsNullOrWhiteSpace($status)) { 'clean' } else { 'dirty' }
            Pop-Location
        }
    } catch { }

    # orphaned processes detection: children that outlived parent not trivial here; count children of PID at last sample
    try { $children = $script:LastChildren; $Execution:Orphaned = ($children | Measure-Object).Count } catch { $Execution:Orphaned = 0 }

    $llmSummary = @{ total_calls = $Execution:LLMCalls.Count; total_cost_usd = ([math]::Round(($Execution:LLMCalls | Measure-Object -Property cost_usd -Sum).Sum,4)); breakdown = @() }
    foreach ($g in $Execution:LLMCalls | Group-Object provider, model) {
        $group = $g.Group | Measure-Object
        $provider = $g.Name.Split(',')[0]
        $model = $g.Name.Split(',')[1]
        $prompt = ($g.Group | Measure-Object -Property prompt_tokens -Sum).Sum
        $cached = ($g.Group | Measure-Object -Property cached_tokens -Sum).Sum
        $comp = ($g.Group | Measure-Object -Property completion_tokens -Sum).Sum
        $cost = ([math]::Round(($g.Group | Measure-Object -Property cost_usd -Sum).Sum,4))
        $lat = ([math]::Round(($g.Group | Measure-Object -Property latency_ms -Average).Average,0))
        $llmSummary.breakdown += @{ provider=$provider.Trim(); model=$model.Trim(); prompt_tokens=$prompt; cached_tokens=$cached; completion_tokens=$comp; cost_usd=$cost; latency_ms=$lat }
    }

    $executionJson = @{ run_id = $Execution:RunId; timestamp = $Execution:StartTime.ToString('o'); git = $git; system = @{ max_ram_mb = $Execution:MaxRamMB; peak_cpu_percent = $Execution:PeakCpu; orphaned_processes = $Execution:Orphaned }; llm_telemetry = $llmSummary; deadlocks = $Execution:Deadlock; duration_ms = ([math]::Round((($Execution:EndTime - $Execution:StartTime).TotalMilliseconds),0)) }

    $outDir = 'D:/HERMES-ENTERPRISE/.verification'
    if (-not (Test-Path $outDir)) { New-Item -Path $outDir -ItemType Directory -Force | Out-Null }
    $outPath = Join-Path $outDir 'execution.json'
    $executionJson | ConvertTo-Json -Depth 6 | Set-Content -Path $outPath -Encoding UTF8
    Write-Host "[Observatory] wrote $outPath"
}

# Export functions
Export-ModuleMember -Function Start-Observatory, Stop-Observatory, Register-LlmCall
