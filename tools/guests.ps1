# Gosti iz 1S:Otel -> imya na TV; pri vyezde/smene gostya - ochistka TV ot uchetok prezhnego gostya.
# Zapusk iz every_<x>.bat: powershell -NoProfile -ExecutionPolicy Bypass -File guests.ps1 <pushkin|city>
# Nastroyki tolko lokalno: C:\hoteltv\guests.cfg (2 stroki: url=<adres bota /exec>, key=<klyuch GUESTS_KEY>) - v GitHub ne klast.
param([string]$h)
$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-Location C:\hoteltv
if (-not (Test-Path guests.cfg)) { exit }
$cfg = @{}; Get-Content guests.cfg | ForEach-Object { $k, $v = $_ -split '=', 2; if ($v) { $cfg[$k.Trim()] = $v.Trim() } }
if (-not $cfg.url -or -not $cfg.key) { exit }
$adb = 'C:\hoteltv\platform-tools\adb.exe'
$form = 'https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse'
$hotel = @{ pushkin = 'Пушкин'; city = 'Сити' }[$h]
function Log($line) { try { $b = [Text.Encoding]::ASCII.GetBytes('entry.1026545154=' + [uri]::EscapeDataString($line)); Invoke-WebRequest -UseBasicParsing -Method Post -Uri $form -ContentType 'application/x-www-form-urlencoded' -Body $b | Out-Null } catch {} }

try { $r = Invoke-RestMethod -UseBasicParsing -TimeoutSec 60 -Uri ("{0}?a=guests&h={1}&k={2}" -f $cfg.url, $h, [uri]::EscapeDataString($cfg.key)) } catch { exit }
if ($r.error) { exit }
$rooms = if ($r.rooms) { $r.rooms } else { $r }
# zashchita: spisok ustarel (>30 min) ili pustoy - nichego ne trogaem, inache vse TV schitali by vyezd
$ageMin = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() - [double]$r.t) / 60000
if (-not $r.t -or $ageMin -gt 30) { exit }
$lines = @(); foreach ($p in $rooms.PSObject.Properties) { if ($p.Name -ne 't' -and "$($p.Value)".Trim()) { $lines += "$($p.Name)`t$($p.Value)" } }
if ($lines.Count -eq 0) { exit }
$b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($lines -join "`n")))
$sig = [Convert]::ToBase64String([Security.Cryptography.MD5]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($b64)))

if (Test-Path tv_ips.txt) { Get-Content tv_ips.txt | Where-Object { $_.Trim() } | ForEach-Object { & $adb connect $_.Trim() | Out-Null } }
$devs = & $adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '\tdevice$' } | ForEach-Object { ($_ -split '\t')[0] }
if (-not (Test-Path guests_state)) { New-Item -ItemType Directory guests_state | Out-Null }
foreach ($d in $devs) {
  $st = "guests_state\" + ($d -replace '[^0-9A-Za-z]', '_') + '.txt'
  # tot zhe spisok uzhe otpravlen na etot TV - propuskaem (ne dergaem TV kazhdye 5 minut)
  if ((Test-Path $st) -and ((Get-Content $st -Raw).Trim() -eq $sig)) { continue }
  $out = (& $adb -s $d shell am broadcast -n ru.hotelkms.tv/.GuestReceiver --es map $b64) -join ' '
  if ($out -notmatch 'data="(\w+)"') { continue }   # na TV staraya versiya prilozheniya - poprobuem v sleduyushchiy raz
  Set-Content $st $sig
  if ($Matches[1] -ne 'OUT') { continue }
  # vyezd / smena gostya: sbrosit dannye storonnih prilozheniy (vhody v kinoteatry) i udalit uchetki Google/Yandeks
  $pk = & $adb -s $d shell pm list packages -3 | ForEach-Object { $_ -replace '^package:', '' } |
        Where-Object { $_ -and $_ -notmatch '^(ru\.hotelkms\.tv|ru\.vk\.store.*|ru\.rustore.*)$' }
  foreach ($p in $pk) { & $adb -s $d shell pm clear $p | Out-Null }
  if (Test-Path rmacc.sh) { & $adb -s $d push rmacc.sh /data/local/tmp/rmacc.sh 2>&1 | Out-Null; $acc = (& $adb -s $d shell sh /data/local/tmp/rmacc.sh) -join ' ' } else { $acc = 'net rmacc.sh' }
  & $adb -s $d shell am start -n ru.hotelkms.tv/.MainActivity | Out-Null
  Log ("{0};выезд гостя;{1};очищено приложений {2};{3}" -f $hotel, $d, @($pk).Count, $acc)
}
