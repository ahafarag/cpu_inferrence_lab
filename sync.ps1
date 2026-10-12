# Copies the working repo to a backup folder. One-way, never deletes at the destination. Includes .git (history backup).
# The destination path is read from sync.local.txt (one line, git-ignored). Example content: [BACKUP_DIR]
# Usage: powershell -File sync.ps1
$src = $PSScriptRoot
$cfg = Join-Path $PSScriptRoot "sync.local.txt"
if (-not (Test-Path $cfg)) { Write-Error "Create sync.local.txt containing the backup folder path"; exit 1 }
$dst = (Get-Content $cfg -TotalCount 1).Trim()
robocopy $src $dst /E /XD models build __pycache__ /XF *.gguf /NJH /NJS /NDL
if ($LASTEXITCODE -ge 8) { Write-Error "robocopy failed ($LASTEXITCODE)"; exit 1 }
exit 0
