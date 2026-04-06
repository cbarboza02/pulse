@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Encerra processos relacionados a Widgets
taskkill /f /im "Widgets.exe" 2>nul
taskkill /f /im "WidgetService.exe" 2>nul
:: Remove o botão de Widgets da barra de tarefas (TaskbarDa = 0 oculta)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d 0 /f
:: Desativa Widgets via Política de Grupo
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d 0 /f
:: Desativa via PolicyManager
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" /v "value" /t REG_DWORD /d 0 /f
:: Para e desativa o serviço de Widgets
sc stop "Widgets" 2>nul
sc config "Widgets" start= disabled 2>nul
exit

:revert
:: Restaura o botão de Widgets na barra de tarefas
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d 1 /f
:: Remove políticas de desativação
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" /v "value" /f 2>nul
:: Reativa o serviço de Widgets
sc config "Widgets" start= auto 2>nul
sc start "Widgets" 2>nul
exit
