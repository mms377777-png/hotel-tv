# tvmdns.ps1 - unicast mDNS-zapros k TV: kakoy port besprovodnoy otladki (_adb-tls-connect._tcp) slushaet TV. Mnogie TV ne vidny po multicast.
# Ispolzovanie: powershell -File tvmdns.ps1 ip1 ip2 ...   Vyvod: "ip port" (tolko chtenie, nichego ne menyaet)
$ErrorActionPreference = 'SilentlyContinue'
function Skip-Name([byte[]]$b, [int]$o) { while ($true) { $l = $b[$o]; if ($l -eq 0) { return $o + 1 }; if (($l -band 0xC0) -eq 0xC0) { return $o + 2 }; $o += $l + 1 } }
function Build-Query([string]$name) {
  $ms = New-Object System.IO.MemoryStream
  $h = [byte[]](0,0, 0,0, 0,1, 0,0, 0,0, 0,0); $ms.Write($h, 0, 12)
  foreach ($p in $name.Split('.')) { $pb = [Text.Encoding]::ASCII.GetBytes($p); $ms.WriteByte([byte]$pb.Length); $ms.Write($pb, 0, $pb.Length) }
  $ms.WriteByte(0); $t = [byte[]](0,12, 0,1); $ms.Write($t, 0, 4)   # PTR, IN
  return $ms.ToArray()
}
$q = Build-Query '_adb-tls-connect._tcp.local'
foreach ($ip in $args) {
  $u = New-Object System.Net.Sockets.UdpClient
  $u.Client.ReceiveTimeout = 1500
  $ports = @()
  try {
    [void]$u.Send($q, $q.Length, $ip, 5353)
    $ep = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
    for ($k = 0; $k -lt 3; $k++) {
      $r = $u.Receive([ref]$ep)
      $o = 12
      $qd = ($r[4] * 256) + $r[5]; $an = ($r[6] * 256) + $r[7]; $ns = ($r[8] * 256) + $r[9]; $ar = ($r[10] * 256) + $r[11]
      for ($i = 0; $i -lt $qd; $i++) { $o = (Skip-Name $r $o) + 4 }
      for ($i = 0; $i -lt ($an + $ns + $ar); $i++) {
        $o = Skip-Name $r $o
        $type = ($r[$o] * 256) + $r[$o + 1]; $len = ($r[$o + 8] * 256) + $r[$o + 9]
        if ($type -eq 33) { $ports += (($r[$o + 14] * 256) + $r[$o + 15]) }
        $o += 10 + $len
      }
    }
  } catch { }
  $u.Close()
  "$ip tls_port=" + (($ports | Select-Object -Unique) -join ',')
}
'konec'
