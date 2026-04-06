@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Limpa Logs e Relatorios de Erros do Windows

:: --- Logs de Eventos do Windows (Event Viewer) ---
:: CORRECAO CRITICA: A sintaxe original usava pipe para um bloco parentesizado:
::   wevtutil el 2>nul | (for /f ... do ...)
:: Pipes para blocos parentesizados NAO funcionam no cmd.exe — o for dentro
:: do bloco nao recebe a saida do pipe. Substituido por for /f com subcomando,
:: que e a unica forma funcional de iterar sobre a saida de um comando externo.
for /f "tokens=*" %%l in ('wevtutil el 2^>nul') do wevtutil cl "%%l" >nul 2>&1

:: --- Relatorios de Erros do Windows (WER) ---
del /f /s /q "%APPDATA%\Microsoft\Windows\WER\*" >nul 2>&1
del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\WER\*" >nul 2>&1
del /f /s /q "%ProgramData%\Microsoft\Windows\WER\ReportArchive\*" >nul 2>&1
del /f /s /q "%ProgramData%\Microsoft\Windows\WER\ReportQueue\*" >nul 2>&1

:: --- Logs de Diagnostico ---
del /f /s /q "%SystemRoot%\Logs\*.log" >nul 2>&1
del /f /s /q "%SystemRoot%\Logs\CBS\*.log" >nul 2>&1
del /f /s /q "%SystemRoot%\Logs\DISM\*" >nul 2>&1
del /f /s /q "%SystemRoot%\Logs\MeasuredBoot\*" >nul 2>&1
del /f /s /q "%SystemRoot%\Logs\NetSetup\*" >nul 2>&1
del /f /s /q "%SystemRoot%\Logs\SIH\*" >nul 2>&1
del /f /s /q "%SystemRoot%\Logs\waasmedic\*" >nul 2>&1

:: --- Arquivos de Minidump (crash dumps) ---
del /f /s /q "%SystemRoot%\Minidump\*" >nul 2>&1
del /f /q "%SystemRoot%\MEMORY.DMP" >nul 2>&1

:: --- Logs do Perfmon e Diagnostico ---
del /f /s /q "%SystemRoot%\System32\LogFiles\*" >nul 2>&1
del /f /s /q "%SystemRoot%\System32\WDI\LogFiles\*" >nul 2>&1

:: --- Historico de confiabilidade ---
del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\WER\ERC\*" >nul 2>&1
exit

:revert
:: Logs e relatorios de erros sao gerados novamente automaticamente pelo sistema
exit
