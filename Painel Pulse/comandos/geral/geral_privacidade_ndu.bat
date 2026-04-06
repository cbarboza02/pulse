@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: ============================================================
:: DESATIVAR NDU (Network Data Usage Monitor)
:: Monitora e registra o uso de dados de rede — impacta RAM/CPU
:: ============================================================

:: Definir Start=4 (Disabled) no registro do serviço
:: (sc config não desativa o NDU de forma permanente por ser um driver)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Ndu" /v "Start" /t REG_DWORD /d 4 /f

:: Tentar parar via sc (pode falhar por ser driver — normal)
sc config "Ndu" start= disabled 2>nul
sc stop   "Ndu" 2>nul

:: NOTA: A desativação completa do NDU só tem efeito após reinicialização.

exit

:revert
:: ============================================================
:: REATIVAR NDU
:: ============================================================

:: Restaurar Start=2 (Automatic)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Ndu" /v "Start" /t REG_DWORD /d 2 /f

sc config "Ndu" start= auto 2>nul
sc start  "Ndu" 2>nul

:: NOTA: A reativação completa do NDU só tem efeito após reinicialização.

exit
