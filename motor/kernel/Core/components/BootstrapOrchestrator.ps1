class BootstrapOrchestrator : IComponent {
    [hashtable]$KernelContext
+    [string]$ProjectName = 'ProyectoTest007'
    BootstrapOrchestrator() : base('BootstrapOrchestrator','1.0',@('PayloadValidator'),@('Bootstrap')){}
    [void] Initialize([hashtable]$ctx){ $this.KernelContext = $ctx; Write-Output 'BootstrapOrchestrator: Initialize' }
    [void] Validate(){ Write-Output 'BootstrapOrchestrator: Validate' }
    [void] Start(){
        $scriptPath = 'D:/HERMES-ENTERPRISE/motor/bootstrap/Start-HermesProject.ps1'
        $outPath = 'D:/HERMES-ENTERPRISE/.verification/bootstrap_stdout.log'
        $errPath = 'D:/HERMES-ENTERPRISE/.verification/bootstrap_stderr.log'

        Write-Output 'BootstrapOrchestrator: Start - launching bootstrap with 5-min timeout'

        if(-not (Test-Path $scriptPath)) { throw 'Bootstrap script not found' }
        if (-not (Test-Path (Split-Path $outPath))) { New-Item -ItemType Directory -Path (Split-Path $outPath) -Force | Out-Null }

        # Build fixed args using injected ProjectName property
        $callArgs = @('-NoProfile')
-        if ($NombreDeProyecto) { $callArgs += @('-File', $scriptPath, '-NombreDeProyecto', $NombreDeProyecto) } else { $callArgs += @('-File', $scriptPath) }
+        $callArgs += @('-File', $scriptPath, '-NombreDeProyecto', $this.ProjectName)

        $p = Start-Process -FilePath "pwsh" -ArgumentList $callArgs -PassThru -WindowStyle Hidden -RedirectStandardOutput $outPath -RedirectStandardError $errPath

        try {
            $p | Wait-Process -Timeout 300 -ErrorAction Stop
            $exitCode = $p.ExitCode
        } catch {
            Write-Output 'BootstrapOrchestrator: TIMEOUT REACHED (5 MIN). Killing process.'
            $p | Stop-Process -Force
            $exitCode = 'TIMEOUT_5_MIN'
        }

        $stdout = if (Test-Path $outPath) { Get-Content $outPath -Raw } else { "" }
        $stderr = if (Test-Path $errPath) { Get-Content $errPath -Raw } else { "" }

        if ($this.KernelContext -ne $null -and $this.KernelContext.ContainsKey('Emit')) {
            & $this.KernelContext['Emit']('BootstrapOrchestrator.Executed', @{ target=$scriptPath; exit_code=$exitCode; stdout=$stdout; stderr=$stderr })
        }
        Write-Output "Bootstrap execution exit code: $exitCode"
    }
    [void] Stop(){ Write-Output 'BootstrapOrchestrator: Stop' }
    [void] Dispose(){ Write-Output 'BootstrapOrchestrator: Dispose' }
}
return [BootstrapOrchestrator]::new()
