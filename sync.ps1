# Copies the working repo (C:) to the Google Drive backup (G:). One-way, never deletes on G:.
# Usage: powershell -File sync.ps1
$src = "[WORKING_COPY_PATH]"
$dst = "[BACKUP_DIR]"
robocopy $src $dst /E /XD .git models build __pycache__ /XF *.gguf /NJH /NJS /NDL
if ($LASTEXITCODE -ge 8) { Write-Error "robocopy failed ($LASTEXITCODE)"; exit 1 }
exit 0
