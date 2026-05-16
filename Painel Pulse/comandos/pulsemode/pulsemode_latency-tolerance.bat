@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Define o timer de latencia do barramento PCI para o menor valor
reg add "HKLM\SYSTEM\CurrentControlSet\Services\pci\Parameters" /v "PciLatencyTimer" /t REG_DWORD /d 32 /f >nul 2>&1
:: Desativa o Link State Power Management do PCIe (elimina latencia de transicao)
powercfg /setacvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 >nul 2>&1
powercfg /setactive SCHEME_CURRENT >nul 2>&1
:: Desativa gerenciamento de energia do barramento PCI
reg add "HKLM\SYSTEM\CurrentControlSet\Services\pci\Parameters" /v "PciDisablePowerManagement" /t REG_DWORD /d 1 /f >nul 2>&1
exit

:revert
:: Restaura configuracoes de latencia padrao do PCIe
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\pci\Parameters" /v "PciLatencyTimer" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\pci\Parameters" /v "PciDisablePowerManagement" /f >nul 2>&1
:: CORRECAO: padrao do plano Balanceado e AC=1 (Moderate), DC=2 (Maximum power savings)
:: Usar AC=2 no revert era mais agressivo em economia de energia do que o padrao
powercfg /setacvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 1 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 2 >nul 2>&1
powercfg /setactive SCHEME_CURRENT >nul 2>&1
exit
