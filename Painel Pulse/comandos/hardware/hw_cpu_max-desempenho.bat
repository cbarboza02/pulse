@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Ativa o plano de energia Desempenho Máximo (Ultimate Performance)
:: Caso nao disponível, ativa o plano Alto Desempenho (High Performance)
:: Duplica o esquema se ainda nao existir
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
:: Busca pelo nome "Ultimate Performance" na lista — o GUID do duplicado e diferente do original
for /f "tokens=4" %%i in ('powercfg -list ^| findstr /i "Ultimate Performance"') do (
    powercfg -setactive %%i
)
:: Fallback: se Ultimate Performance não estiver disponível, ativa Alto Desempenho
powercfg -list | findstr /i "Ultimate Performance" >nul 2>&1
if errorlevel 1 (
    powercfg -setactive SCHEME_MIN
)
:: Garante processador em 100% minimo e maximo no plano ativo
powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100
powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100
powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100
powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100
:: Modo de boost agressivo do processador (2 = Agressivo)
powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTMODE 2
powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTMODE 2
powercfg /setactive SCHEME_CURRENT
exit

:revert
:: Restaura o plano Equilibrado padrao e configura os valores de throttling originais
powercfg -setactive SCHEME_BALANCED
:: Padrao do plano Equilibrado: PROCTHROTTLEMIN=5, PROCTHROTTLEMAX=100, PERFBOOSTMODE=1
powercfg -setacvalueindex SCHEME_BALANCED SUB_PROCESSOR PROCTHROTTLEMIN 5
powercfg -setacvalueindex SCHEME_BALANCED SUB_PROCESSOR PROCTHROTTLEMAX 100
powercfg -setdcvalueindex SCHEME_BALANCED SUB_PROCESSOR PROCTHROTTLEMIN 5
powercfg -setdcvalueindex SCHEME_BALANCED SUB_PROCESSOR PROCTHROTTLEMAX 100
powercfg -setacvalueindex SCHEME_BALANCED SUB_PROCESSOR PERFBOOSTMODE 1
powercfg -setdcvalueindex SCHEME_BALANCED SUB_PROCESSOR PERFBOOSTMODE 1
powercfg /setactive SCHEME_BALANCED
exit
