@echo off
if /i "%~1"=="restaurar" goto restaurar
if /i "%~1"=="padrao" goto padrao
exit /b

:restaurar
:: Restaurar/Corrigir Bluetooth
:: O Bluetooth nao e desabilitado diretamente pelas otimizacoes, mas algumas
:: politicas de privacidade e permissoes podem afetar seu funcionamento.

:: --- 1. Servicos de Bluetooth ---
:: Garante que os servicos essenciais do Bluetooth estejam configurados corretamente.
:: Todos tem startup Manual por padrao (iniciam sob demanda ou por trigger do hardware).
sc config bthserv    start= demand >nul 2>&1
sc config BthAvctpSvc start= demand >nul 2>&1
sc config BTAGService start= demand >nul 2>&1

:: Inicia o servico principal imediatamente para que o hardware seja detectado
sc start bthserv >nul 2>&1

:: --- 2. Permissoes de acesso ao Bluetooth (CapabilityAccessManager) ---
:: O script PS1 de usuario nega acesso a "location", "contacts", etc., mas preserva
:: Bluetooth. Mesmo assim, restauramos explicitamente como correcao.
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\bluetooth"     /v "Value" /t REG_SZ /d "Allow" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\bluetoothSync" /v "Value" /t REG_SZ /d "Allow" /f

:: Permissao a nivel de sistema (necessario para apps acessarem Bluetooth)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\bluetooth"     /v "Value" /t REG_SZ /d "Allow" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\bluetoothSync" /v "Value" /t REG_SZ /d "Allow" /f

:: --- 3. Remove politicas de bloqueio de Bluetooth (se existirem) ---
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Wireless\GPTWirelessPolicy" /v "DisableBluetoothDevice" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v "DisableBluetooth" /f 2>nul

:: --- 4. Remove override de Wi-Fi Sense que pode afetar conectividade sem fio ---
:: O script PS1 de maquina desativa Wi-Fi Sense, o que pode indiretamente afetar
:: o comportamento de pareamento automatico. Mantem desativado (correto).

:: --- 5. Garante que o Radio Management Service esteja ativo ---
:: RadioMgmtSvc gerencia os radios de Wi-Fi e Bluetooth
sc config RadioMgmtSvc start= demand >nul 2>&1
sc start  RadioMgmtSvc              >nul 2>&1

:: --- 6. Re-escaneia dispositivos Bluetooth para reenumera-los ---
pnputil /scan-devices >nul 2>&1

echo [OK] Configuracoes de Bluetooth restauradas. Se o problema persistir, verifique o driver do adaptador Bluetooth no Gerenciador de Dispositivos.
exit /b

:padrao
:: Re-aplicar estado das configuracoes de Bluetooth pos-otimizacao
:: (O Bluetooth nao e desabilitado pelas otimizacoes - este bloco garante
:: que as permissoes de privacidade estejam no estado esperado pelo sistema otimizado.)

:: Mantem Bluetooth permitido (nao alterado pelas otimizacoes)
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\bluetooth"     /v "Value" /t REG_SZ /d "Allow" /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\bluetoothSync" /v "Value" /t REG_SZ /d "Allow" /f

:: Servicos de Bluetooth em modo Manual (padrao - nao modificados pelas otimizacoes)
sc config bthserv     start= demand >nul 2>&1
sc config BthAvctpSvc start= demand >nul 2>&1
sc config BTAGService start= demand >nul 2>&1
exit /b
