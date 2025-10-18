param(
  [Parameter(Mandatory=$true)][string]$SiteName,
  [Parameter(Mandatory=$true)][string]$AppPoolName,
  [Parameter(Mandatory=$true)][string]$SitePath,
  [Parameter(Mandatory=$true)][string]$BackupRoot
)

$ErrorActionPreference = 'Stop'
Import-Module WebAdministration

$latest = Get-ChildItem $BackupRoot -Filter "$SiteName-*.zip" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $latest) { throw "No backups found in $BackupRoot" }

Write-Host "Rolling back using $($latest.FullName)"

# Take offline + stop
$appOffline = Join-Path $SitePath 'app_offline.htm'
"Rollback in progress..." | Out-File -FilePath $appOffline -Encoding utf8
if (Test-Path IIS:\AppPools\$AppPoolName) {
  Stop-WebAppPool -Name $AppPoolName
}

# Clear current site files
Get-ChildItem $SitePath -Force | Where-Object { $_.Name -ne 'app_offline.htm' } | Remove-Item -Recurse -Force

# Restore
Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
[System.IO.Compression.ZipFile]::ExtractToDirectory($latest.FullName, $SitePath, $true)

# Bring back online
if (Test-Path IIS:\AppPools\$AppPoolName) {
  Start-WebAppPool -Name $AppPoolName
}
Remove-Item $appOffline -ErrorAction SilentlyContinue

Write-Host "Rollback completed."
