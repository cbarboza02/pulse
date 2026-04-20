@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: ============================================================
:: OTIMIZAR PESQUISA DO WINDOWS
:: 1. Desativar Pesquisa na Web
:: 2. Desativar Pesquisa Segura
:: ============================================================

:: Desativar sugestoes de pesquisa na Web via barra de pesquisa
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer"       /v "DisableSearchBoxSuggestions"                  /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "DisableWebSearch"                              /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchUseWeb"                         /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchUseWebOverMeteredConnections"   /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowSearchToUseLocation"                      /t REG_DWORD /d 0 /f

:: Desativar Cortana e integracao Bing na pesquisa
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana"          /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortanaAboveLock" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"   /v "BingSearchEnabled"     /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"   /v "CortanaConsent"        /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"   /v "DeviceHistoryEnabled"  /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"   /v "HistoryViewEnabled"    /t REG_DWORD /d 0 /f
:: Define icone de pesquisa compacto (1 = icone, 0 = oculto, 2 = caixa completa)
:: NOTA: esta preferencia e pessoal — apenas altera a aparencia, nao a funcionalidade de pesquisa
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"   /v "SearchboxTaskbarMode"  /t REG_DWORD /d 1 /f

:: Desativar pesquisa na nuvem e indexacao de conteudo online
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCloudSearch"          /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "EnableDynamicContentInWSB"  /t REG_DWORD /d 0 /f

:: Desativar Pesquisa Segura (SafeSearch / filtro adulto)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "SafeSearchPermissions"  /t REG_DWORD /d 0 /f
exit

:revert
reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer"       /v "DisableSearchBoxSuggestions"                /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "DisableWebSearch"                            /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchUseWeb"                       /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchUseWebOverMeteredConnections" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowSearchToUseLocation"                    /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana"                                /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortanaAboveLock"                       /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCloudSearch"                            /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "EnableDynamicContentInWSB"                   /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "SafeSearchPermissions"                       /f 2>nul

reg add    "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled"   /t REG_DWORD /d 1 /f
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "CortanaConsent"       /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "DeviceHistoryEnabled" /f 2>nul
:: CORRECAO: HistoryViewEnabled foi definido no apply mas nao era revertido — corrigido
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "HistoryViewEnabled"   /f 2>nul
:: CORRECAO: SearchboxTaskbarMode foi definido no apply (valor 1) mas nao era revertido.
:: O padrao do Windows 11 e 1 (icone compacto), porem o usuario pode ter qualquer valor.
:: Deletar a chave restaura o comportamento padrao do Windows sem sobrescrever preferencia anterior.
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /f 2>nul
exit
