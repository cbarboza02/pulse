@echo off
:: Verifica qual argumento foi enviado
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa o timeout de sleep (standby) no AC e bateria
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
:: Desativa o timeout de hibernacao no AC e bateria
powercfg /change hibernate-timeout-ac 0
powercfg /change hibernate-timeout-dc 0
:: Desativa o timeout do monitor no AC e bateria
powercfg /change monitor-timeout-ac 0
powercfg /change monitor-timeout-dc 0
:: Desativa o timeout do disco no AC e bateria
powercfg /change disk-timeout-ac 0
powercfg /change disk-timeout-dc 0
exit

:revert
:: Restaura os timeouts padrao do Windows (plano Balanceado)
powercfg /change standby-timeout-ac 30
powercfg /change standby-timeout-dc 15
powercfg /change hibernate-timeout-ac 0
powercfg /change hibernate-timeout-dc 0
powercfg /change monitor-timeout-ac 10
powercfg /change monitor-timeout-dc 5
powercfg /change disk-timeout-ac 20
powercfg /change disk-timeout-dc 10
exit
