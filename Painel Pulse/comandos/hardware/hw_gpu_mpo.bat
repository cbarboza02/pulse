@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa o Multi-Plane Overlay (MPO) do DWM
:: MPO pode causar stuttering, tela preta momentanea e artefatos visuais em algumas GPUs
reg add "HKLM\SOFTWARE\Microsoft\Windows\Dwm" /v "OverlayTestMode" /t REG_DWORD /d 5 /f
exit

:revert
:: Remove o override e restaura o MPO ao comportamento padrao do driver
reg delete "HKLM\SOFTWARE\Microsoft\Windows\Dwm" /v "OverlayTestMode" /f 2>nul
exit
