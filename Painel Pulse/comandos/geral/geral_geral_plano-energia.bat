@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto pulseos
exit /b

:apply
for /f "tokens=4" %%G in ('powercfg /list ^| findstr /i "Ultimate"') do set "EXIST_GUID=%%G"
if not defined EXIST_GUID for /f "tokens=4" %%G in ('powercfg /list ^| findstr /i "Desempenho Maximo"') do set "EXIST_GUID=%%G"
if defined EXIST_GUID (
    powercfg /setactive %EXIST_GUID%
    exit /b
)
for /f "tokens=4" %%G in ('powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 ^| findstr "GUID"') do set "NEW_GUID=%%G"
if defined NEW_GUID (
    reg add "HKCU\SOFTWARE\Optimizations" /v PowerPlanCreatedGUID /t REG_SZ /d "%NEW_GUID%" /f >nul 2>&1
    powercfg /changename %NEW_GUID% "Desempenho Maximo" "Plano de alto desempenho para jogos e aplicacoes exigentes" >nul 2>&1
    powercfg /setactive %NEW_GUID%
) else (
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
)
exit /b

:pulseos
:: Padrao PulseOS: Alto Desempenho ativo.
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
for /f "tokens=3" %%G in ('reg query "HKCU\SOFTWARE\Optimizations" /v PowerPlanCreatedGUID 2^>nul ^| findstr PowerPlanCreatedGUID') do set "CREATED_GUID=%%G"
if defined CREATED_GUID powercfg /delete %CREATED_GUID% >nul 2>&1
reg delete "HKCU\SOFTWARE\Optimizations" /v PowerPlanCreatedGUID /f >nul 2>&1
exit /b
