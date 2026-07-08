function Calculate-Duration {
    <#
    .SYNOPSIS
        Calcula la duración entre dos timestamps ISO
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Start,
        
        [Parameter(Mandatory)]
        [string]$End
    )
    
    try {
        $startTime = [DateTime]::Parse($Start)
        $endTime = [DateTime]::Parse($End)
        $duration = $endTime - $startTime
        
        $hours = [math]::Floor($duration.TotalHours).ToString("00")
        $minutes = $duration.Minutes.ToString("00")
        $seconds = $duration.Seconds.ToString("00")
        
        return "$hours`:$minutes`:$seconds"
    } catch {
        return "N/A"
    }
}
