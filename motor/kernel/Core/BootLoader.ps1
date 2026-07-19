. 'D:/HERMES-ENTERPRISE/motor/kernel/Contracts/IComponent.ps1'

function Load-Descriptors {
    param([string]$DescriptorsPath)
    $files = Get-ChildItem -Path $DescriptorsPath -Filter '*.json' -ErrorAction SilentlyContinue
    $descs = @()
    foreach ($f in $files) { $descs += (Get-Content $f.FullName | ConvertFrom-Json) }
    return $descs
}

function Validate-Descriptors {
    param([object[]]$Descriptors)
    foreach ($d in $Descriptors) {
        if (-not $d.id) { throw "Descriptor missing id" }
    }
    return $true
}

function Build-ComponentFactory {
    param([object]$Descriptor)
    # For demo: create a dummy component factory that returns an instance implementing IComponent
    $script = {
        param()
        class DummyComponent : IComponent {
            DummyComponent(){ base('DummyComponent','1.0',@(),@()) }
            [void] Initialize([hashtable]$ctx){ Write-Output "DummyComponent Initialize" }
            [void] Validate(){ Write-Output "DummyComponent Validate" }
            [void] Start(){ Write-Output "DummyComponent Start" }
            [void] Stop(){ Write-Output "DummyComponent Stop" }
            [void] Dispose(){ Write-Output "DummyComponent Dispose" }
        }
        return [DummyComponent]::new()
    }
    return $script
}

function BootLoader_Run {
    param([string]$DescriptorsPath ,[ServiceContainer]$Container)
    $descs = Load-Descriptors -DescriptorsPath $DescriptorsPath
    Validate-Descriptors -Descriptors $descs
    $components = @()
    foreach ($d in $descs) {
        $factory = Build-ComponentFactory -Descriptor $d
        $components += @{ id=$d.id; factory=$factory }
    }
    return $components
}

Export-ModuleMember -Function Load-Descriptors,Validate-Descriptors,Build-ComponentFactory,BootLoader_Run
