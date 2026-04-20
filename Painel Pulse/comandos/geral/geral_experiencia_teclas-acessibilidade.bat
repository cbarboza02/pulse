@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa Teclas de Aderencia (StickyKeys) e seu atalho de teclado (Shift 5x)
:: Flags 506 = desativa o atalho de ativacao (HotkeyActive removido de 510)
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v Flags /t REG_SZ /d "506" /f

:: Desativa Teclas de Filtro (FilterKeys) e seu atalho de teclado (segurar Shift por 8s)
:: Flags 122 = desativa o atalho de ativacao (HotkeyActive removido de 126)
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v Flags /t REG_SZ /d "122" /f

:: Desativa Teclas de Alternancia (ToggleKeys) e seu atalho de teclado (segurar NumLock por 5s)
:: Flags 58 = desativa o atalho de ativacao (HotkeyActive removido de 62)
reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v Flags /t REG_SZ /d "58" /f
exit

:revert
:: Restaura os valores padrao das Teclas de Acessibilidade (hotkeys reativados)
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v Flags /t REG_SZ /d "510" /f
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v Flags /t REG_SZ /d "126" /f
reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v Flags /t REG_SZ /d "62" /f
exit
