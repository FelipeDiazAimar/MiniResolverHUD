$procs = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'"
foreach ($p in $procs) {
  if (($p.CommandLine -like '*-File*qa-watcher*') -or ($p.CommandLine -like '*-File*qa-hud*')) {
    Write-Output ("MATAR " + $p.ProcessId)
    try { Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop; Write-Output ("OK " + $p.ProcessId) } catch { Write-Output ("FAIL " + $p.ProcessId) }
  }
}
Remove-Item "$env:TEMP\qa-watcher.pid" -ErrorAction SilentlyContinue
Write-Output "limpio"
