@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Desativa as tarefas agendadas de diagnostico de memoria do Windows
schtasks /Change /TN "\Microsoft\Windows\MemoryDiagnostic\ProcessMemoryDiagnosticEvents" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\MemoryDiagnostic\RunFullMemoryDiagnostic" /Disable >nul 2>&1
:: Desativa o servico de diagnostico de memoria (msdiag)
sc stop msdiag >nul 2>&1
sc config msdiag start= disabled >nul 2>&1
exit

:revert
:: Reativa as tarefas agendadas de diagnostico de memoria
schtasks /Change /TN "\Microsoft\Windows\MemoryDiagnostic\ProcessMemoryDiagnosticEvents" /Enable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\MemoryDiagnostic\RunFullMemoryDiagnostic" /Enable >nul 2>&1
:: Reativa o servico de diagnostico de memoria
sc config msdiag start= auto >nul 2>&1
sc start msdiag >nul 2>&1
exit
