# tvscan.ps1 - TOLKO CHTENIE: kto zhiv v seti 192.168.1.x i na kakom portu otvechaet adb (5555 ili sluchaynyy port besprovodnoy otladki 30000-50000)
$ErrorActionPreference = 'SilentlyContinue'
$net = '192.168.1'
$pings = 1..254 | ForEach-Object { $ip = "$net.$_"; $p = New-Object System.Net.NetworkInformation.Ping; [pscustomobject]@{ip=$ip; t=$p.SendPingAsync($ip, 700)} }
[void][System.Threading.Tasks.Task]::WaitAll(@($pings | ForEach-Object { $_.t }), 8000)
$alive = @($pings | Where-Object { $_.t.IsCompleted -and $_.t.Result.Status -eq 'Success' } | ForEach-Object { $_.ip })
$arp = arp -a | Where-Object { $_ -match '^\s+192\.168\.1\.' }
foreach ($ip in $alive) {
  $mac = ($arp | Where-Object { $_ -match ([regex]::Escape($ip) + '\s') } | Select-Object -First 1) -replace '^\s*\S+\s+(\S+).*$','$1'
  $open = New-Object System.Collections.Generic.List[int]
  $ports = @(5555) + (30000..50000)
  for ($i = 0; $i -lt $ports.Count; $i += 1000) {
    $batch = $ports[$i..([Math]::Min($i + 999, $ports.Count - 1))]
    $cs = foreach ($pt in $batch) { $c = New-Object System.Net.Sockets.TcpClient; [pscustomobject]@{c=$c; pt=$pt; r=$c.ConnectAsync($ip, $pt)} }
    [void][System.Threading.Tasks.Task]::WaitAll(@($cs | ForEach-Object { $_.r }), 600)
    foreach ($x in $cs) { if ($x.r.IsCompleted -and -not $x.r.IsFaulted -and $x.c.Connected) { $open.Add($x.pt) }; $x.c.Close() }
  }
  "$ip mac=$mac open=" + ($open -join ',')
}
"alive=" + $alive.Count
