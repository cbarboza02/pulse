@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Ativa StickyKeys, FilterKeys e ToggleKeys e seus atalhos de teclado
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v Flags /t REG_SZ /d "510" /f
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v Flags /t REG_SZ /d "126" /f
reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v Flags /t REG_SZ /d "62" /f
reg add "HKU\.DEFAULT\Control Panel\Accessibility\StickyKeys" /v Flags /t REG_SZ /d "510" /f
reg add "HKU\.DEFAULT\Control Panel\Accessibility\Keyboard Response" /v Flags /t REG_SZ /d "126" /f
reg add "HKU\.DEFAULT\Control Panel\Accessibility\ToggleKeys" /v Flags /t REG_SZ /d "62" /f
reg load "HKLM\TempHive" "%SystemDrive%\Users\Default\NTUSER.DAT" >nul 2>&1
reg add "HKLM\TempHive\Control Panel\Accessibility\StickyKeys" /v Flags /t REG_SZ /d "510" /f >nul 2>&1
reg add "HKLM\TempHive\Control Panel\Accessibility\Keyboard Response" /v Flags /t REG_SZ /d "126" /f >nul 2>&1
reg add "HKLM\TempHive\Control Panel\Accessibility\ToggleKeys" /v Flags /t REG_SZ /d "62" /f >nul 2>&1
reg unload "HKLM\TempHive" >nul 2>&1
exit

:revert
:: HKCU - usuario atual
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v Flags /t REG_SZ /d "506" /f
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v Flags /t REG_SZ /d "122" /f
reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v Flags /t REG_SZ /d "58" /f
:: HKU\.DEFAULT - padrao para novos usuarios
reg add "HKU\.DEFAULT\Control Panel\Accessibility\StickyKeys" /v Flags /t REG_SZ /d "506" /f
reg add "HKU\.DEFAULT\Control Panel\Accessibility\Keyboard Response" /v Flags /t REG_SZ /d "122" /f
reg add "HKU\.DEFAULT\Control Panel\Accessibility\ToggleKeys" /v Flags /t REG_SZ /d "58" /f
:: Novo hive padrao (novos usuarios criados apos a instalacao)
reg load "HKLM\TempHive" "%SystemDrive%\Users\Default\NTUSER.DAT" >nul 2>&1
reg add "HKLM\TempHive\Control Panel\Accessibility\StickyKeys" /v Flags /t REG_SZ /d "506" /f >nul 2>&1
reg add "HKLM\TempHive\Control Panel\Accessibility\Keyboard Response" /v Flags /t REG_SZ /d "122" /f >nul 2>&1
reg add "HKLM\TempHive\Control Panel\Accessibility\ToggleKeys" /v Flags /t REG_SZ /d "58" /f >nul 2>&1
reg unload "HKLM\TempHive" >nul 2>&1
exit
