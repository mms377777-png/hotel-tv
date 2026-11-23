# wol.ps1 <mac> <ip> <broadcast> - magic packet (UDP 9 i 7) shirokoveschatelno i napryamuyu. Bystryy, tolko otpravka.
param([string]$mac, [string]$ip, [string]$bc)
$m = ($mac -replace '[^0-9A-Fa-f]', '')
if ($m.Length -ne 12) { 'bad mac'; exit 1 }
$mb = for ($i = 0; $i -lt 12; $i += 2) { [Convert]::ToByte($m.Substring($i, 2), 16) }
$pkt = [byte[]](,0xFF * 6) + [byte[]]($mb * 16)
$u = New-Object System.Net.Sockets.UdpClient
$u.EnableBroadcast = $true
foreach ($t in @($bc, $ip)) { foreach ($p in 9, 7) { [void]$u.Send($pkt, $pkt.Length, $t, $p) } }
$u.Close()
"wol sent mac=$m ip=$ip bc=$bc len=$($pkt.Length)"
