@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Reduz o atraso inicial antes da repeticao de tecla ao minimo
:: KeyboardDelay: 0 = menor atraso (~250ms), 3 = maior atraso (~1000ms)
reg add "HKCU\Control Panel\Keyboard" /v KeyboardDelay /t REG_SZ /d "0" /f
:: Aumenta a taxa de repeticao da tecla ao maximo
:: KeyboardSpeed: 0 = mais lento (~2/s), 31 = mais rapido (~30/s)
reg add "HKCU\Control Panel\Keyboard" /v KeyboardSpeed /t REG_SZ /d "31" /f
:: Aplica as mudancas na sessao atual sem precisar reiniciar
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Add-Type 'using System; using System.Runtime.InteropServices; public class K { [DllImport(\"user32.dll\")] public static extern bool SystemParametersInfo(uint a, uint b, uint c, uint d); }'; [K]::SystemParametersInfo(0x001B, 0, 31, 3) | Out-Null; [K]::SystemParametersInfo(0x001A, 0, 0, 3) | Out-Null"
exit

:revert
:: Restaura o atraso e taxa de repeticao do teclado ao padrao do Windows
:: KeyboardDelay: 1 (~500ms), KeyboardSpeed: 31 (padrao do Windows)
reg add "HKCU\Control Panel\Keyboard" /v KeyboardDelay /t REG_SZ /d "1" /f
reg add "HKCU\Control Panel\Keyboard" /v KeyboardSpeed /t REG_SZ /d "31" /f
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Add-Type 'using System; using System.Runtime.InteropServices; public class K { [DllImport(\"user32.dll\")] public static extern bool SystemParametersInfo(uint a, uint b, uint c, uint d); }'; [K]::SystemParametersInfo(0x001B, 0, 31, 3) | Out-Null; [K]::SystemParametersInfo(0x001A, 0, 1, 3) | Out-Null"
exit
