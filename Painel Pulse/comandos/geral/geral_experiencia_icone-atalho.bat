@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply

taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul

del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache_*.db" >nul 2>&1

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ms=New-Object IO.MemoryStream;$bw=New-Object IO.BinaryWriter($ms);$bw.Write([uint16]0);$bw.Write([uint16]1);$bw.Write([uint16]1);$bw.Write([byte]16);$bw.Write([byte]16);$bw.Write([byte]0);$bw.Write([byte]0);$bw.Write([uint16]1);$bw.Write([uint16]32);$bw.Write([uint32]1128);$bw.Write([uint32]22);$bw.Write([uint32]40);$bw.Write([int32]16);$bw.Write([int32]32);$bw.Write([uint16]1);$bw.Write([uint16]32);$bw.Write([uint32]0);$bw.Write([uint32]0);$bw.Write([int32]0);$bw.Write([int32]0);$bw.Write([uint32]0);$bw.Write([uint32]0);$bw.Write([byte[]]::new(1024));1..16|%%{$bw.Write([byte[]]@(255,255,0,0))};[IO.File]::WriteAllBytes('%SystemRoot%\Blank.ico',$ms.ToArray())"

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons" /v "29" /t REG_SZ /d "%SystemRoot%\Blank.ico" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\NamingTemplates" /v "ShortcutNameTemplate" /t REG_SZ /d "%s.lnk" /f

start explorer.exe
exit

:revert

taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul

del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache_*.db" >nul 2>&1

:: Remove o icone em branco e restaura a seta padrao dos atalhos
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons" /v "29" /f 2>nul

:: Restaura o sufixo ' - Atalho' nos novos atalhos
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\NamingTemplates" /v "ShortcutNameTemplate" /f 2>nul

:: Remove o arquivo de icone em branco criado
del /f /q "%SystemRoot%\Blank.ico" 2>nul

start explorer.exe
exit
