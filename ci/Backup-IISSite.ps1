param(
  [Parameter(Mandatory=$true)][string]$SiteName,
  [Parameter(Mandatory=$true)][string]$SitePath,
  [Parameter(Mandatory=$true)][string]$BackupRoot,
  [int]$Retain = 5
)

$ErrorActionPreference = 'Stop'

if (!(Test-Path $BackupRoot)) { New-Item -ItemType Directory -Path $BackupRoot | Out-Null }

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupFile = Join-Path $BackupRoot "$($SiteName)-$timestamp.zip"

Write-Host "Backing up $SitePath to $backupFile"
Add-Type -AssemblyName 'System.IO.Compression.FileSystem'

# Create zip of current site folder
[System.IO.Compression.ZipFile]::CreateFromDirectory($SitePath, $backupFile)

# Retention
$backups = Get-ChildItem $BackupRoot -Filter "$SiteName-*.zip" | Sort-Object LastWriteTime -Descending
if ($backups.Count -gt $Retain) {
  $toDelete = $backups[$Retain..($backups.Count - 1)]
  $toDelete | ForEach-Object {
    Write-Host "Removing old backup $($_.FullName)"
    Remove-Item $_.FullName -Force
  }
}

Write-Host "Backup completed."
