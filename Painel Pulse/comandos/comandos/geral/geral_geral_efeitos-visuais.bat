@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: ============================================================
:: EFEITOS VISUAIS - Define modo personalizado (Custom)
:: VisualFXSetting: 0=Windows decide, 1=Melhor aparencia,
::                  2=Melhor desempenho, 3=Personalizado
:: ============================================================
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d 3 /f

:: ============================================================
:: 1. DESATIVAR TRANSPARENCIA DO WINDOWS
:: ============================================================
:: HKCU e a chave que o Windows efetivamente le para a transparencia da interface
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 0 /f
:: REMOVIDO: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize\EnableTransparency
:: Nao e uma chave padrao lida pelo Windows para controle de transparencia — sem efeito real.
:: REMOVIDO: HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization\EnableTransparency
:: Nao e uma chave de politica de grupo documentada para transparencia da interface.

:: ============================================================
:: 2. DESATIVAR ANIMACOES DO WINDOWS
:: ============================================================
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "0" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d 0 /f
reg add "HKCU\Control Panel\Desktop" /v "DragFullWindows" /t REG_SZ /d "0" /f

:: ============================================================
:: 3. DESATIVAR SOMBRAS
:: ============================================================
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewShadow" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\DWM" /v "EnableAeroPeek" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\DWM" /v "AlwaysHibernateThumbnails" /t REG_DWORD /d 0 /f

:: ============================================================
:: 4. CONFIGURACOES INDIVIDUAIS DE APARENCIA
::    Mantidas: Miniaturas, Retangulo translucido, Fontes ClearType
::    Desativadas: todas as demais animacoes, sombras, deslizamentos
:: ============================================================
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "IconsOnly" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewAlphaSelect" /t REG_DWORD /d 1 /f
reg add "HKCU\Control Panel\Desktop" /v "FontSmoothing" /t REG_SZ /d "2" /f
reg add "HKCU\Control Panel\Desktop" /v "FontSmoothingType" /t REG_DWORD /d 2 /f
reg add "HKCU\Control Panel\Desktop" /v "FontSmoothingGamma" /t REG_DWORD /d 1000 /f
reg add "HKCU\Control Panel\Desktop" /v "FontSmoothingOrientation" /t REG_DWORD /d 1 /f

:: UserPreferencesMask: controla animacoes, deslizamentos, sombra do cursor e comportamentos de UI
:: Valor 9012038010000000 = animacoes e sombras de cursor desativadas, essencial mantido
:: CORRECAO: removida a linha duplicada (era definida duas vezes no arquivo original)
reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d 9012038010000000 /f

:: Aumenta tempo de hover para miniaturas da taskbar (evita pop-up de preview ao passar o mouse)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ExtendedUIHoverTime" /t REG_DWORD /d 30000 /f

:: Desativa animacao de primeiro logon
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "EnableFirstLogonAnimation" /t REG_DWORD /d 0 /f

:: Aplica imediatamente
rundll32.exe user32.dll,UpdatePerUserSystemParameters ,1,True
exit

:revert
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 1 /f
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "1" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d 1 /f
reg add "HKCU\Control Panel\Desktop" /v "DragFullWindows" /t REG_SZ /d "1" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewShadow" /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\DWM" /v "EnableAeroPeek" /t REG_DWORD /d 1 /f
:: CORRECAO: AlwaysHibernateThumbnails foi adicionado pelo apply — deletado no revert para restaurar estado original
reg delete "HKCU\Software\Microsoft\Windows\DWM" /v "AlwaysHibernateThumbnails" /f 2>nul
reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d 9E3E078012000000 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "IconsOnly" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewAlphaSelect" /t REG_DWORD /d 1 /f
reg add "HKCU\Control Panel\Desktop" /v "FontSmoothing" /t REG_SZ /d "2" /f
reg add "HKCU\Control Panel\Desktop" /v "FontSmoothingType" /t REG_DWORD /d 2 /f
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ExtendedUIHoverTime" /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "EnableFirstLogonAnimation" /t REG_DWORD /d 1 /f
rundll32.exe user32.dll,UpdatePerUserSystemParameters ,1,True
exit
