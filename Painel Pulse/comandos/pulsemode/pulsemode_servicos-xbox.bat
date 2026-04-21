@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: ---- GameDVR - Desativa captura de gameplay em segundo plano
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_EFSEFeatureFlags" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f

:: ---- GameBar - Desativa a barra de jogo e notificacoes relacionadas
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "ShowStartupPanel" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "GamePanelStartupTipIndex" /t REG_DWORD /d 3 /f
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 0 /f

:: ---- Servicos Xbox nao essenciais para jogos/Xbox Live/Microsoft Store
:: CORRECAO: adicionados >nul 2>&1 nos sc config (imprimiam SUCCESS no console)
:: XboxGipSvc: gerencia acessorios Xbox (controles via USB/Bluetooth) -> manual
sc config XboxGipSvc start= demand >nul 2>&1
sc stop XboxGipSvc 2>nul
:: XboxNetApiSvc: API de rede Xbox, raramente usada por jogos modernos -> manual
sc config XboxNetApiSvc start= demand >nul 2>&1
sc stop XboxNetApiSvc 2>nul
:: XblAuthManager: ESSENCIAL para Xbox Live e Microsoft Store -> mantido automatico
:: XblGameSave: ESSENCIAL para saves em nuvem de jogos GamePass -> mantido automatico
exit

:revert
:: ---- GameDVR - Restaura captura de gameplay
reg delete "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /f 2>nul
reg delete "HKCU\System\GameConfigStore" /v "GameDVR_EFSEFeatureFlags" /f 2>nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 1 /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /f 2>nul

:: ---- GameBar - Restaura barra de jogo
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "GameDVR_Enabled" /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\GameBar" /v "ShowStartupPanel" /f 2>nul
:: CORRECAO: GamePanelStartupTipIndex foi adicionado pelo apply — deletado no revert
reg delete "HKCU\SOFTWARE\Microsoft\GameBar" /v "GamePanelStartupTipIndex" /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\GameBar" /v "AllowAutoGameMode" /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\GameBar" /v "AutoGameModeEnabled" /f 2>nul

:: ---- Servicos Xbox - Restaura inicio manual (padrao real do Windows)
:: CORRECAO: XboxGipSvc e XboxNetApiSvc tem startup type "demand" (Manual) por padrao
:: no Windows 10/11, NAO "auto". O revert original colocava "auto" incorretamente,
:: deixando o sistema em estado diferente do original apos a reversao.
sc config XboxGipSvc start= demand >nul 2>&1
sc config XboxNetApiSvc start= demand >nul 2>&1
exit
