# Skachat APK iz RuStore po imeni paketa: powershell -ExecutionPolicy Bypass -File getapk.ps1 ru.kinopoisk.tv out.apk
param([string]$pkg, [string]$out)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$info = Invoke-RestMethod -Uri "https://backapi.rustore.ru/applicationData/overallInfo/$pkg"
$id = $info.body.appId
$body = @{ appId = $id; firstInstall = $true; withoutSplits = $true } | ConvertTo-Json
$dl = Invoke-RestMethod -Method Post -Uri "https://backapi.rustore.ru/applicationData/v2/download-link" -ContentType 'application/json' -Body $body
$url = $null
if ($dl.body.downloadUrls) { $url = $dl.body.downloadUrls[0].url }
if (-not $url -and $dl.body.apkUrl) { $url = $dl.body.apkUrl }
if (-not $url) {
  $dl = Invoke-RestMethod -Method Post -Uri "https://backapi.rustore.ru/applicationData/download-link" -ContentType 'application/json' -Body $body
  if ($dl.body.downloadUrls) { $url = $dl.body.downloadUrls[0].url } elseif ($dl.body.apkUrl) { $url = $dl.body.apkUrl }
}
Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing
$len = (Get-Item $out).Length
Write-Output "$pkg $($info.body.versionName) $len $url"
