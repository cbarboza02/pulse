@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa a compressao de memoria do Windows (Memory Compression)
:: Elimina o overhead de CPU usado para comprimir/descomprimir paginas em memoria
powershell -NoProfile -ExecutionPolicy Bypass -Command "Disable-MMAgent -MemoryCompression"
exit

:revert
:: Reativa a compressao de memoria do Windows
powershell -NoProfile -ExecutionPolicy Bypass -Command "Enable-MMAgent -MemoryCompression"
exit
