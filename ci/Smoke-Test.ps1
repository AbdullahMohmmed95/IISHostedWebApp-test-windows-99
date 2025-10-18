param([Parameter(Mandatory=$true)][string]$Url)

$ErrorActionPreference = 'Stop'
Start-Sleep -Seconds 3   # small warm-up
try {
  $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 15
  if ($resp.StatusCode -ne 200) {
    throw "Non-200 status: $($resp.StatusCode)"
  }
  Write-Host "Smoke test OK: $Url"
} catch {
  Write-Error "Smoke test FAILED: $($_.Exception.Message)"
  exit 1
}
