@echo off
if /i "%~1"=="restaurar" goto restaurar
if /i "%~1"=="padrao" goto padrao
exit /b

:restaurar
:: Restaurar app Fotos do Windows 11 como padrao (remove Visualizador Classico)
reg delete "HKLM\SOFTWARE\RegisteredApplications" /v "Windows Photo Viewer" /f 2>nul
for %%e in (.bmp .dib .gif .jfif .jpe .jpeg .jpg .png .tif .tiff .wdp .ico) do (
    reg delete "HKLM\SOFTWARE\Classes\%%e\OpenWithProgids" /v "PhotoViewer.FileAssoc.Tiff" /f 2>nul
    reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\%%e\OpenWithProgids" /v "PhotoViewer.FileAssoc.Tiff" /f 2>nul
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$exts=@('.jpg','.jpeg','.png','.bmp','.gif','.tif','.tiff','.jpe','.jfif','.wdp','.ico','.dib'); foreach($e in $exts){ $p='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\'+$e+'\UserChoice'; if(Test-Path $p){try{Remove-Item $p -Force -ErrorAction SilentlyContinue}catch{}} }; try{Add-Type -TypeDefinition 'using System;using System.Runtime.InteropServices;public class S32{[DllImport(\"shell32.dll\")]public static extern void SHChangeNotify(int e,int f,IntPtr a,IntPtr b);}';[S32]::SHChangeNotify(0x08000000,0,[IntPtr]::Zero,[IntPtr]::Zero)}catch{}"
exit /b

:padrao
:: Re-registrar Visualizador de Fotos Classico do Windows
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$base='HKLM:\SOFTWARE\Classes\PhotoViewer.FileAssoc.Tiff'; if(-not(Test-Path $base)){New-Item $base -Force|Out-Null}; $open='$base\shell\open'; New-Item -Path '$open\command' -Force|Out-Null; Set-ItemProperty -Path $open -Name 'MuiVerb' -Value '@%%ProgramFiles%%\Windows Photo Viewer\photoviewer.dll,-3043' -Type ExpandString -Force; Set-ItemProperty -Path '$open\command' -Name '(default)' -Value '%%SystemRoot%%\System32\rundll32.exe \"%%ProgramFiles%%\Windows Photo Viewer\PhotoViewer.dll\", ImageView_Fullscreen %%1' -Type ExpandString -Force; $exts=@('.bmp','.dib','.gif','.jfif','.jpe','.jpeg','.jpg','.png','.tif','.tiff','.wdp','.ico'); foreach($e in $exts){ $p='HKLM:\SOFTWARE\Classes\'+$e+'\OpenWithProgids'; if(-not(Test-Path $p)){New-Item $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name 'PhotoViewer.FileAssoc.Tiff' -Value '' -Type String -Force; $up='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\'+$e+'\OpenWithProgids'; if(-not(Test-Path $up)){New-Item $up -Force|Out-Null}; Set-ItemProperty -Path $up -Name 'PhotoViewer.FileAssoc.Tiff' -Value ([byte[]]@()) -Type Binary -Force }; Set-ItemProperty -Path 'HKLM:\SOFTWARE\RegisteredApplications' -Name 'Windows Photo Viewer' -Value 'SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities' -Type String -Force; try{Add-Type -TypeDefinition 'using System;using System.Runtime.InteropServices;public class S32{[DllImport(\"shell32.dll\")]public static extern void SHChangeNotify(int e,int f,IntPtr a,IntPtr b);}';[S32]::SHChangeNotify(0x08000000,0,[IntPtr]::Zero,[IntPtr]::Zero)}catch{}"
exit /b
