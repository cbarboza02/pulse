@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa o Historico da Area de Transferencia (painel Win+V)
:: Obs: copiar/colar (Ctrl+C / Ctrl+V) continua funcionando normalmente
reg add "HKCU\Software\Microsoft\Clipboard" /v EnableClipboardHistory /t REG_DWORD /d 0 /f
:: Desativa a sincronizacao da Area de Transferencia entre dispositivos
reg add "HKCU\Software\Microsoft\Clipboard" /v EnableCloudClipboard /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Clipboard" /v CloudClipboardAutomaticUpload /t REG_DWORD /d 0 /f
:: Politicas de bloqueio em nivel de sistema
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v AllowClipboardHistory /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v AllowCrossDeviceClipboard /t REG_DWORD /d 0 /f
:: Limpa o historico atual da Area de Transferencia
powershell -NoProfile -Command ^
  "try {" ^
  "  Add-Type -AssemblyName 'Windows.ApplicationModel.DataTransfer' -ErrorAction Stop;" ^
  "  [Windows.ApplicationModel.DataTransfer.Clipboard]::ClearHistory() | Out-Null" ^
  "} catch {}" >nul 2>&1
exit

:revert
:: Reativa o Historico da Area de Transferencia
reg add "HKCU\Software\Microsoft\Clipboard" /v EnableClipboardHistory /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Clipboard" /v EnableCloudClipboard /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Clipboard" /v CloudClipboardAutomaticUpload /t REG_DWORD /d 1 /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v AllowClipboardHistory /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v AllowCrossDeviceClipboard /f >nul 2>&1
exit
