@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Salva o GUID do plano ativo atual para reversao
set "PREV_GUID="
for /f "tokens=4" %%G in ('powercfg /getactivescheme ^| findstr "GUID"') do set "PREV_GUID=%%G"
if defined PREV_GUID (
    reg add "HKCU\SOFTWARE\Optimizations" /v PowerPlanPreviousGUID /t REG_SZ /d "%PREV_GUID%" /f >nul 2>&1
)

:: Verifica se o plano Desempenho Maximo ja existe na lista
:: CORRECAO: findstr nao suporta "|" como operador OR em um unico padrao sem /C:.
:: A versao original usava "Ultimate\|Desempenho M" que e sintaxe invalida para findstr.
:: Substituido por duas buscas separadas sequenciais.
set "EXIST_GUID="
for /f "tokens=4" %%G in ('powercfg /list ^| findstr /i "Ultimate"') do set "EXIST_GUID=%%G"
if not defined EXIST_GUID (
    for /f "tokens=4" %%G in ('powercfg /list ^| findstr /i "Desempenho Maximo"') do set "EXIST_GUID=%%G"
)

if defined EXIST_GUID (
    :: Plano ja existe, apenas ativa
    powercfg /setactive %EXIST_GUID%
    goto :done_apply
)

:: Cria o plano Desempenho Maximo (Ultimate Performance) e captura o GUID gerado
set "NEW_GUID="
for /f "tokens=4" %%G in ('powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 ^| findstr "GUID"') do set "NEW_GUID=%%G"

if defined NEW_GUID (
    :: Salva o GUID criado para poder remover no revert
    reg add "HKCU\SOFTWARE\Optimizations" /v PowerPlanCreatedGUID /t REG_SZ /d "%NEW_GUID%" /f >nul 2>&1
    :: Renomeia o plano para identificacao
    powercfg /changename %NEW_GUID% "Desempenho Maximo" "Plano de alto desempenho para jogos e aplicacoes exigentes" >nul 2>&1
    :: Ativa o plano
    powercfg /setactive %NEW_GUID%
) else (
    :: Fallback: ativa Alto Desempenho se Ultimate Performance nao estiver disponivel
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
)

:done_apply
exit

:revert
:: Recupera o GUID do plano anterior ao apply
set "PREV_GUID="
for /f "tokens=2*" %%A in ('reg query "HKCU\SOFTWARE\Optimizations" /v PowerPlanPreviousGUID 2^>nul ^| findstr "PowerPlanPreviousGUID"') do set "PREV_GUID=%%B"

:: Se nao encontrou o plano anterior, usa o Balanceado como fallback
if not defined PREV_GUID set "PREV_GUID=381b4222-f694-41f0-9685-ff5bb260df2e"

:: Ativa o plano anterior
powercfg /setactive %PREV_GUID%

:: Remove o plano criado pela otimizacao (se foi criado por ela)
set "CREATED_GUID="
for /f "tokens=2*" %%A in ('reg query "HKCU\SOFTWARE\Optimizations" /v PowerPlanCreatedGUID 2^>nul ^| findstr "PowerPlanCreatedGUID"') do set "CREATED_GUID=%%B"
if defined CREATED_GUID (
    powercfg /delete %CREATED_GUID% >nul 2>&1
)

:: Limpa as entradas de registro da otimizacao
reg delete "HKCU\SOFTWARE\Optimizations" /v PowerPlanPreviousGUID /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Optimizations" /v PowerPlanCreatedGUID /f >nul 2>&1
exit
