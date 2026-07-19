class EventBus {
    hidden [hashtable] $subs
    EventBus() { $this.subs = @{} }
    [void] Subscribe([string]$event, [scriptblock]$handler) {
        if (-not $this.subs.ContainsKey($event)) { $this.subs[$event] = @() }
        $this.subs[$event] += $handler
    }
    [void] Publish([string]$event, [object]$payload) {
        if ($this.subs.ContainsKey($event)) {
            foreach ($h in $this.subs[$event]) { & $h $payload }
        }
    }
    [string[]] Subscriptions() { return $this.subs.Keys }
}
