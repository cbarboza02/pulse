@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Limpa o banco de dados do Historico de Atividades do Windows (Timeline)
:: LIMPEZA APENAS — nao desativa nenhuma funcionalidade

:: CORRECAO: A versao original desativava o Activity Feed via registro (EnableActivityFeed,
:: PublishUserActivities, UploadUserActivities, TailoredExperiencesWithDiagnosticDataEnabled).
:: Isso e uma operacao de "desativar", nao de "limpar". Todas essas linhas foram removidas.
:: Para desativar o Activity Feed, usar o arquivo geral_privacidade_linha-do-tempo.bat.

:: Limpa o banco de dados do historico de atividades do usuario atual
:: CORRECAO: del nao suporta wildcards no meio de caminhos (L.*).
:: Substituido por loop for /d que percorre cada subpasta individualmente.
for /d %%p in ("%LOCALAPPDATA%\ConnectedDevicesPlatform\*") do (
    del /f /q "%%p\ActivitiesCache.db"     >nul 2>&1
    del /f /q "%%p\ActivitiesCache.db-shm" >nul 2>&1
    del /f /q "%%p\ActivitiesCache.db-wal" >nul 2>&1
)
exit

:revert
:: Historico de atividades e gerado novamente automaticamente pelo sistema
:: Nao ha configuracoes alteradas para reverter
exit
