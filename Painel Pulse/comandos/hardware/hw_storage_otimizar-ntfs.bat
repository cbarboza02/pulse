@echo off
:: Verifica qual argumento foi enviado
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa a atualização do timestamp de último acesso em arquivos e pastas
fsutil behavior set disablelastaccess 1
:: Confirma via registro (redundância)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v "NtfsDisableLastAccessUpdate" /t REG_DWORD /d 1 /f
:: Desativa a geração de nomes curtos no formato 8.3 no NTFS
fsutil behavior set disable8dot3 1
:: Desativa também para todos os volumes via registro
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v "NtfsDisable8dot3NameCreation" /t REG_DWORD /d 1 /f
exit

:revert
:: Reativa a atualização do timestamp de último acesso
fsutil behavior set disablelastaccess 0
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v "NtfsDisableLastAccessUpdate" /t REG_DWORD /d 0 /f
:: Reativa a geração de nomes 8.3 (padrão do Windows)
fsutil behavior set disable8dot3 0
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v "NtfsDisable8dot3NameCreation" /t REG_DWORD /d 0 /f
exit
