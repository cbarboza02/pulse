@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Limpa Cache do DirectX (Shader Cache e caches de GPU)

:: --- Shader Cache do DirectX (pasta principal do sistema) ---
del /f /s /q "%LOCALAPPDATA%\D3DSCache\*" >nul 2>&1
rd /s /q "%LOCALAPPDATA%\D3DSCache" >nul 2>&1

:: --- Shader Cache do DirectX 12 ---
del /f /s /q "%LOCALAPPDATA%\DirectX\*" >nul 2>&1

:: --- Cache de Shader da NVIDIA (se aplicável) ---
del /f /s /q "%LOCALAPPDATA%\NVIDIA\DXCache\*" >nul 2>&1
del /f /s /q "%LOCALAPPDATA%\NVIDIA\GLCache\*" >nul 2>&1
del /f /s /q "%AppData%\NVIDIA\ComputeCache\*" >nul 2>&1

:: --- Cache de Shader da AMD (se aplicável) ---
del /f /s /q "%LOCALAPPDATA%\AMD\DXCache\*" >nul 2>&1
del /f /s /q "%LOCALAPPDATA%\AMD\GLCache\*" >nul 2>&1

:: --- Cache de Shader da Intel (se aplicável) ---
del /f /s /q "%LOCALAPPDATA%\Intel\ShaderCache\*" >nul 2>&1

:: --- Cache de Shader do Steam (DX e Vulkan) ---
del /f /s /q "%LOCALAPPDATA%\Steam\shadercache\*" >nul 2>&1

:: --- Cache de Shader via limpeza de disco (componente DXCache) ---
:: Configura e executa limpeza selecionada de componente DXCache
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\D3D Shader Cache" /v "StateFlags0099" /t REG_DWORD /d 2 /f >nul 2>&1
cleanmgr /sagerun:99 >nul 2>&1

exit

:revert
:: O cache do DirectX é regenerado automaticamente ao executar aplicações 3D/jogos
:: Nenhuma ação de reversão necessária
exit
