# Evita doble instancia + deja PID para ON/OFF (sin Global\, no pide admin)
$qaMutex = New-Object System.Threading.Mutex($false, "QA-OpenCode-Watcher")
if (-not $qaMutex.WaitOne(0)) { exit }
try { $PID | Out-File "$env:TEMP\qa-watcher.pid" -Encoding ascii -Force } catch {}
"$(Get-Date -Format o) start pid=$PID" | Out-File "$env:TEMP\qa-watcher.log" -Append -Encoding utf8
$Host.UI.RawUI.WindowTitle = "QA-OpenCode"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$MAXLEN = 2000
$DEBOUNCE = 2.0
$MODEL = $env:OPENCODE_MODEL
if ([string]::IsNullOrWhiteSpace($MODEL)) { $MODEL = "opencode-go/muse-spark-1.3-contributor" }
$sid = "ses_qa_" + (Get-Date -Format "yyyyMMdd_HHmmss")
"$(Get-Date -Format o) sesion: $sid" | Out-File "$env:TEMP\qa-watcher.log" -Append -Encoding utf8

function Show-Noti($title, $msg) {
  return  # notis apagadas: solo HUD
}

Show-Noti "QA activado" "Copiá un texto (Ctrl+C), esperá 2s y te respondo acá."

$candidate = ""; $t0 = [DateTime]::MinValue; $done = ""; $doneTime = [DateTime]::MinValue
$candImg = ""; $candBytes = $null; $doneImg = ""
while ($true) {
  $imgObj = $null
  try { if ([System.Windows.Forms.Clipboard]::ContainsImage()) { $imgObj = [System.Windows.Forms.Clipboard]::GetImage() } } catch { $imgObj = $null }
  if ($imgObj -ne $null) {
    $h = ""
    try {
      $ms = New-Object IO.MemoryStream
      $imgObj.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
      $bytes = $ms.ToArray(); $ms.Dispose(); $imgObj.Dispose()
      $sha = New-Object System.Security.Cryptography.SHA1Managed
      $h = [BitConverter]::ToString($sha.ComputeHash($bytes)).Replace("-",""); $sha.Dispose()
    } catch { $h = "" }
    if ($h -ne "" -and $h -ne $doneImg) {
      if ($h -ne $candImg) { $candImg = $h; $candBytes = $bytes; $t0 = Get-Date }
      elseif (((Get-Date) - $t0).TotalSeconds -ge $DEBOUNCE) {
        $doneImg = $h; $candImg = ""; $done = ""
        $fp = "$env:TEMP\qa-clip.png"
        try {
          [IO.File]::WriteAllBytes($fp, $candBytes); $candBytes = $null
          "$(Get-Date -Format o) pregunta: [imagen]" | Out-File "$env:TEMP\qa-watcher.log" -Append -Encoding utf8
          $prompt = "Mira la imagen. Si contiene una pregunta, respondela en 1 sola linea corta, max 100 caracteres, directo, sin intro. Si no hay pregunta, describi en 1 linea que se ve."
          $ans = (opencode run --session $sid --title "QA clipboard" --model $MODEL -f $fp $prompt 2>$null | Out-String).Trim()
          if ([string]::IsNullOrWhiteSpace($ans)) { $ans = "(sin respuesta)" }
          "$(Get-Date -Format o) respuesta: $ans" | Out-File "$env:TEMP\qa-watcher.log" -Append -Encoding utf8
          try { $ans | Out-File "$env:TEMP\qa-hud.txt" -Encoding utf8 -Force } catch {}
          Show-Noti "OpenCode" $ans
        } catch {
          Show-Noti "OpenCode error" $_.Exception.Message
        }
      }
    }
    Start-Sleep -Milliseconds 400; continue
  } else { $candImg = ""; $doneImg = "" }
  try {
    $t = (Get-Clipboard -Raw -ErrorAction SilentlyContinue)
    if ($null -ne $t) { $t = $t.Trim() } else { $t = "" }
  } catch { $t = "" }
  if ($t -eq "") { $candidate = ""; $done = ""; Start-Sleep -Milliseconds 400; continue }
  $isNew = ($t -ne $done)
  if ($t.Length -gt 2 -and $t.Length -lt $MAXLEN -and $isNew) {
    if ($t -ne $candidate) { $candidate = $t; $t0 = Get-Date }
    elseif (((Get-Date) - $t0).TotalSeconds -ge $DEBOUNCE) {
      $q = $candidate; $done = $q; $doneTime = Get-Date; $candidate = ""
      try {
        "$(Get-Date -Format o) pregunta: $q" | Out-File "$env:TEMP\qa-watcher.log" -Append -Encoding utf8
        $prompt = "Respondé en 1 sola línea corta, directo, máx 100 caracteres, sin intro. Texto: $q"
        $ans = (opencode run --session $sid --title "QA clipboard" --model $MODEL $prompt 2>$null | Out-String).Trim()
        if ([string]::IsNullOrWhiteSpace($ans)) { $ans = "(sin respuesta)" }
        "$(Get-Date -Format o) respuesta: $ans" | Out-File "$env:TEMP\qa-watcher.log" -Append -Encoding utf8
        try { $ans | Out-File "$env:TEMP\qa-hud.txt" -Encoding utf8 -Force } catch {}
        Show-Noti "OpenCode" $ans
      } catch {
        Show-Noti "OpenCode error" $_.Exception.Message
      }
    }
  } else { $candidate = "" }
  Start-Sleep -Milliseconds 400
}

