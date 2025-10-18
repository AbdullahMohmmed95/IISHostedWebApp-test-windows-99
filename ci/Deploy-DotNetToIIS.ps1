param(
  [Parameter(Mandatory=$true)][string]$SiteName,
  [Parameter(Mandatory=$true)][string]$AppPoolName,
  [Parameter(Mandatory=$true)][string]$SitePath,
  [Parameter(Mandatory=$true)][string]$PackagePath
)

$ErrorActionPreference = 'Stop'

function Ensure-Dir($p) { if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p | Out-Null } }

Ensure-Dir $SitePath

# Take app offline to avoid file locks
$appOffline = Join-Path $SitePath 'app_offline.htm'
"Updating... please wait." | Out-File -FilePath $appOffline -Encoding utf8

# Stop app pool for safe file replace
Import-Module WebAdministration
if (Test-Path IIS:\AppPools\$AppPoolName) {
  Write-Host "Stopping app pool $AppPoolName"
  Stop-WebAppPool -Name $AppPoolName
}

# Mirror new published files to site
$robocopyLog = Join-Path $env:TEMP "deploy-$($SiteName)-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$rc = & robocopy $PackagePath $SitePath /MIR /XF app_offline.htm /R:2 /W:2 /NFL /NDL /NP /LOG:$robocopyLog
Write-Host "Robocopy exit code: $rc (logged to $robocopyLog)"

# Start app pool
if (Test-Path IIS:\AppPools\$AppPoolName) {
  Write-Host "Starting app pool $AppPoolName"
  Start-WebAppPool -Name $AppPoolName
}

# Bring app online
Remove-Item $appOffline -ErrorAction SilentlyContinue

Write-Host "Deploy completed."
