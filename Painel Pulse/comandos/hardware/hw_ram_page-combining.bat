@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa o Page Combining (mesclagem de paginas de memoria com conteudo identico)
:: Elimina o overhead de CPU causado pela varredura e mesclagem continua de paginas
powershell -NoProfile -ExecutionPolicy Bypass -Command "Disable-MMAgent -PageCombining"
exit

:revert
:: Reativa o Page Combining para economizar memoria RAM via mesclagem de paginas
powershell -NoProfile -ExecutionPolicy Bypass -Command "Enable-MMAgent -PageCombining"
exit
