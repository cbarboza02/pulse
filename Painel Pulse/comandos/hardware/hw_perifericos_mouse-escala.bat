@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa a aceleracao do mouse (Enhanced Pointer Precision)
:: Garante que cada contagem fisica do sensor corresponda a exatamente 1 pixel na tela
reg add "HKCU\Control Panel\Mouse" /v MouseSpeed /t REG_SZ /d "0" /f
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold1 /t REG_SZ /d "0" /f
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold2 /t REG_SZ /d "0" /f
:: Desativa o Enhanced Pointer Precision no registro
reg add "HKCU\Control Panel\Mouse" /v MouseSensitivity /t REG_SZ /d "10" /f
:: Configuracao da curva de movimento: valores identicos = linha reta = sem aceleracao
reg add "HKCU\Control Panel\Mouse" /v SmoothMouseXCurve /t REG_BINARY /d 0000000000000000C0CC0C0000000000809919000000000040662600000000000099330000000000 /f
reg add "HKCU\Control Panel\Mouse" /v SmoothMouseYCurve /t REG_BINARY /d 0000000000000000000038000000000000007000000000000000A800000000000000E00000000000 /f
:: Aplica configuracao via SystemParametersInfo
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Add-Type 'using System; using System.Runtime.InteropServices; public class M { [DllImport(\"user32.dll\")] public static extern bool SystemParametersInfo(uint a, uint b, int[] c, uint d); }'; [M]::SystemParametersInfo(4, 0, @(0,0), 3) | Out-Null"
exit

:revert
:: Restaura os valores padrao do Windows para aceleracao do mouse
reg add "HKCU\Control Panel\Mouse" /v MouseSpeed /t REG_SZ /d "1" /f
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold1 /t REG_SZ /d "6" /f
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold2 /t REG_SZ /d "10" /f
reg add "HKCU\Control Panel\Mouse" /v MouseSensitivity /t REG_SZ /d "10" /f
:: Remove as curvas customizadas para restaurar o padrao
reg delete "HKCU\Control Panel\Mouse" /v SmoothMouseXCurve /f 2>nul
reg delete "HKCU\Control Panel\Mouse" /v SmoothMouseYCurve /f 2>nul
exit
