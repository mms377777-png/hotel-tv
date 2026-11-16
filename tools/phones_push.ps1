# Razovaya vygruzka (tolko chtenie) so stoyki Pushkina: HTTP GET stranicy statusa telefonov Flyingvoice BEZ vhoda + ARP.
# Parolej ne vvodim i ne podbiraem, nastroyki telefonov ne menyaem. Na kazhdyj telefon 2 zaprosa (/ i /status.htm), odin prohod.
param(
  [string[]]$Ips = @('192.168.1.122','192.168.1.200','192.168.1.201','192.168.1.202','192.168.1.203','192.168.1.204','192.168.1.205','192.168.1.206','192.168.1.208','192.168.1.209','192.168.1.210','192.168.1.211','192.168.1.212','192.168.1.213','192.168.1.214','192.168.1.215','192.168.1.216'),
  [string]$Out = 'phones_out.txt',
  [int]$Port = 80
)
$ErrorActionPreference = 'Stop'
$Skip = '(?i)pass|pwd|secret|token|auth|key|cookie'
function Mask([string]$s) { [regex]::Replace($s, '(?i)(pass\w*|pwd|secret|token|api\s*key|auth\w*|cookie)\s*[:=]?\s*\S*', '[skryto]') }
function Cut([string]$s, [int]$n) { if ($s.Length -gt $n) { $s.Substring(0, $n) } else { $s } }
function Clean([string]$s) { ([regex]::Replace($s, '[\r\n\t;]+', ' ')).Trim() }
function Strip([string]$h) {
  $h = [regex]::Replace($h, '(?is)<(script|style)\b.*?</\1>', ' ')
  $h = [regex]::Replace($h, '<[^>]+>', ' ')
  $h = [System.Net.WebUtility]::HtmlDecode($h)
  [regex]::Replace($h, '\s+', ' ').Trim()
}
function Get-Page([string]$url) {
  $r = @{ status = ''; body = ''; auth = '' }
  $h = $Out + '.hdr'; $b = $Out + '.body'
  Remove-Item $h, $b -ErrorAction SilentlyContinue
  try {
    & curl.exe -s -m 6 --noproxy '*' -A 'Mozilla/5.0' --max-filesize 300000 -D $h -o $b $url 2>$null | Out-Null
    if (Test-Path $h) {
      $hl = [System.IO.File]::ReadAllLines($h)
      $m = [regex]::Match([string]$hl[0], 'HTTP/\S+\s+(\d{3})')
      if ($m.Success) { $r.status = $m.Groups[1].Value }
      foreach ($l in $hl) { if ($l -match '(?i)^WWW-Authenticate:\s*(.*)$') { $r.auth = $Matches[1] } }
    }
    if (Test-Path $b) { $r.body = Cut ([System.IO.File]::ReadAllText($b, [System.Text.Encoding]::UTF8)) 200000 }
    if ($r.status -eq '') { $r.status = 'err:net' }
  } catch {
    $r.status = 'err:' + (Cut (Clean $_.Exception.Message) 60)
  }
  Remove-Item $h, $b -ErrorAction SilentlyContinue
  $r
}
function Extract([string]$body) {
  $f = @()
  foreach ($m in [regex]::Matches($body, '(?is)<input\b[^>]*>')) {
    $t = $m.Value
    $n = [regex]::Match($t, '(?i)\b(?:name|id)\s*=\s*["'']?([^"''\s>]+)').Groups[1].Value
    $v = [regex]::Match($t, '(?i)\bvalue\s*=\s*["'']([^"'']*)["'']').Groups[1].Value
    $ty = [regex]::Match($t, '(?i)\btype\s*=\s*["'']?([^"''\s>]+)').Groups[1].Value
    if ($ty -match '(?i)password' -or $n -match $Skip) { continue }
    if ($v -ne '' -and $f.Count -lt 25) { $f += (Cut (Clean $n) 30) + '=' + (Cut (Clean $v) 60) }
  }
  $txt = Mask (Strip $body)
  $k = @()
  foreach ($m in [regex]::Matches($txt, '(?i)(display\s*name|register\s*name|user\s*id|user\s*name|phone\s*number|sip\s*account|account|\bMAC\b|model|product)[^<>]{0,80}')) {
    if ($m.Value -match $Skip) { continue }
    if ($k.Count -lt 12) { $k += Cut (Clean $m.Value) 100 }
  }
  $title = Mask ([regex]::Match($body, '(?is)<title[^>]*>(.*?)</title>').Groups[1].Value)
  @{ title = Cut (Clean $title) 80; fields = ($f -join '|'); kw = ($k -join '|'); txt = Cut $txt 400 }
}

$lines = @()
$ok = 0
foreach ($ip in $Ips) {
  $base = 'http://' + $ip
  if ($Port -ne 80) { $base = $base + ':' + $Port }
  foreach ($p in @('/', '/status.htm')) {
    $pg = Get-Page ($base + $p)
    $e = Extract $pg.body
    if ($pg.status -eq '200' -and ($e.fields -ne '' -or $e.kw -ne '')) { $ok++ }
    $lines += ($ip + ';' + $p + ';http=' + $pg.status + ';auth=' + (Cut (Clean $pg.auth) 60) + ';title=' + $e.title + ';fields=' + $e.fields + ';kw=' + $e.kw + ';txt=' + $e.txt)
  }
}
$arp = @()
try {
  foreach ($l in (& arp.exe -a)) {
    $m = [regex]::Match([string]$l, '^\s*(192\.168\.1\.\d+)\s+([0-9a-fA-F-]{17})')
    if ($m.Success -and ($Ips -contains $m.Groups[1].Value)) { $arp += ('arp;' + $m.Groups[1].Value + ';' + $m.Groups[2].Value) }
  }
} catch { $arp += 'arp;err;' + (Cut (Clean $_.Exception.Message) 60) }

$head = 'Pushkin;telefony;v27;ips=' + $Ips.Count + ';stranic_s_dannymi=' + $ok + ';arp=' + $arp.Count
$all = @($head) + $lines + $arp
[System.IO.File]::WriteAllText($Out, ($all -join "`r`n"), (New-Object System.Text.UTF8Encoding($false)))
