@echo off
if /i "%~1"=="apply" goto apply
if /i "%~1"=="revert" goto revert
exit

:apply
:: Restaura o Visualizador de Fotos do Windows (Classic Photo Viewer) para todos os tipos de imagem
:: NOTA: No Windows 10/11, associacoes de arquivo via HKCU\Classes funcionam como override
:: e aparecem em "Abrir com". Para definir como padrao definitivo, o usuario deve ir em
:: Configuracoes > Aplicativos > Aplicativos padrao, pois o Windows protege o UserChoice com hash.

:: Registra as capacidades do Visualizador de Fotos Classico no sistema
reg add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".bmp"  /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".dib"  /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".gif"  /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".jfif" /t REG_SZ /d "PhotoViewer.FileAssoc.Jpeg" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".jpe"  /t REG_SZ /d "PhotoViewer.FileAssoc.Jpeg" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".jpeg" /t REG_SZ /d "PhotoViewer.FileAssoc.Jpeg" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".jpg"  /t REG_SZ /d "PhotoViewer.FileAssoc.Jpeg" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".png"  /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".tif"  /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".tiff" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".wdp"  /t REG_SZ /d "PhotoViewer.FileAssoc.Wdp"  /f
:: Registra o programa nas Capacidades do Windows (necessario para aparecer em "Abrir com")
reg add "HKLM\SOFTWARE\RegisteredApplications" /v "Windows Photo Viewer" /t REG_SZ /d "SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities" /f

:: Registra as associacoes de arquivo no usuario atual (override sobre o padrao do sistema)
reg add "HKCU\SOFTWARE\Classes\.jpg"  /ve /t REG_SZ /d "PhotoViewer.FileAssoc.Jpeg" /f
reg add "HKCU\SOFTWARE\Classes\.jpeg" /ve /t REG_SZ /d "PhotoViewer.FileAssoc.Jpeg" /f
reg add "HKCU\SOFTWARE\Classes\.jpe"  /ve /t REG_SZ /d "PhotoViewer.FileAssoc.Jpeg" /f
reg add "HKCU\SOFTWARE\Classes\.jfif" /ve /t REG_SZ /d "PhotoViewer.FileAssoc.Jpeg" /f
reg add "HKCU\SOFTWARE\Classes\.png"  /ve /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
reg add "HKCU\SOFTWARE\Classes\.bmp"  /ve /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
reg add "HKCU\SOFTWARE\Classes\.dib"  /ve /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
reg add "HKCU\SOFTWARE\Classes\.gif"  /ve /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
reg add "HKCU\SOFTWARE\Classes\.tif"  /ve /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
reg add "HKCU\SOFTWARE\Classes\.tiff" /ve /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
reg add "HKCU\SOFTWARE\Classes\.wdp"  /ve /t REG_SZ /d "PhotoViewer.FileAssoc.Wdp"  /f
exit

:revert
:: Remove as associacoes do Visualizador de Fotos Classico do usuario atual
reg delete "HKCU\SOFTWARE\Classes\.jpg"  /f 2>nul
reg delete "HKCU\SOFTWARE\Classes\.jpeg" /f 2>nul
reg delete "HKCU\SOFTWARE\Classes\.jpe"  /f 2>nul
reg delete "HKCU\SOFTWARE\Classes\.jfif" /f 2>nul
reg delete "HKCU\SOFTWARE\Classes\.png"  /f 2>nul
reg delete "HKCU\SOFTWARE\Classes\.bmp"  /f 2>nul
reg delete "HKCU\SOFTWARE\Classes\.dib"  /f 2>nul
reg delete "HKCU\SOFTWARE\Classes\.gif"  /f 2>nul
reg delete "HKCU\SOFTWARE\Classes\.tif"  /f 2>nul
reg delete "HKCU\SOFTWARE\Classes\.tiff" /f 2>nul
reg delete "HKCU\SOFTWARE\Classes\.wdp"  /f 2>nul
:: CORRECAO: Remove tambem as entradas HKLM adicionadas pelo apply (estavam sendo ignoradas no revert original)
reg delete "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".bmp"  /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".dib"  /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".gif"  /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".jfif" /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".jpe"  /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".jpeg" /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".jpg"  /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".png"  /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".tif"  /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".tiff" /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".wdp"  /f 2>nul
reg delete "HKLM\SOFTWARE\RegisteredApplications" /v "Windows Photo Viewer" /f 2>nul
exit
