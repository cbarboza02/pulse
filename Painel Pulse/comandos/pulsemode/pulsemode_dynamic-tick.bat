@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa Dynamic Tick — o timer do sistema passa a usar intervalo fixo, reduzindo latencia
:: e imprevisibilidade no agendamento de interrupcoes
bcdedit /set disabledynamictick yes
:: Sincronizacao de TSC aprimorada entre nucleos (reduz desvio do contador de tempo entre CPUs)
bcdedit /set tscsyncpolicy Enhanced
:: REMOVIDO: bcdedit /set useplatformclock true
:: Esse comando HABILITA o HPET (High Precision Event Timer) como fonte de clock principal.
:: Em hardware moderno (Ryzen, Intel 8a+ geracao), o HPET tem latencia de acesso maior que o
:: TSC interno da CPU. Forcar useplatformclock=true aumenta overhead de interrupcoes e pode
:: PIORAR latencia em jogos. O Windows ja escolhe o melhor clock disponivel por padrao (TSC).
exit

:revert
:: Restaura Dynamic Tick ao comportamento padrao do Windows
bcdedit /set disabledynamictick no
bcdedit /deletevalue tscsyncpolicy 2>nul
:: Garante que useplatformclock nao esteja forcado (caso tenha sido definido anteriormente)
bcdedit /deletevalue useplatformclock 2>nul
exit
