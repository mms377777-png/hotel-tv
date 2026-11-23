# tvscan2.ps1 - TOLKO CHTENIE: zhivye IP 192.168.1.x (ping) + MAC iz arp + otvechaet li port 5555
$ErrorActionPreference = 'SilentlyContinue'
$net = '192.168.1'
$jobs = 1..254 | ForEach-Object { $ip = "$net.$_"; $p = New-Object System.Net.NetworkInformation.Ping; [pscustomobject]@{ip=$ip; t=$p.SendPingAsync($ip, 900)} }
[void][System.Threading.Tasks.Task]::WaitAll(@($jobs | ForEach-Object { $_.t }), 6000)
$arp = arp -a | Where-Object { $_ -match '^\s+192\.168\.1\.' }
foreach ($j in $jobs) {
  $ok = $j.t.IsCompleted -and $j.t.Result.Status -eq 'Success'
  $mac = ($arp | Where-Object { $_ -match ([regex]::Escape($j.ip) + '\s') } | Select-Object -First 1) -replace '^\s*\S+\s+(\S+).*$','$1'
  if ($ok -or $mac) {
    $c = New-Object System.Net.Sockets.TcpClient; $r = $c.ConnectAsync($j.ip, 5555); [void]$r.Wait(400)
    $p5555 = if ($c.Connected) {'open'} elseif ($r.IsFaulted) {'closed'} else {'drop'}
    $c.Close()
    "$($j.ip) ping=$ok mac=$mac p5555=$p5555"
  }
}
'konec'
