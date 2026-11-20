@echo off
setlocal EnableExtensions EnableDelayedExpansion
title ONLYOFFICE - Revertir parche es-AR

rem Restaura cada sdk-all-min.js desde su copia .bak_esAR (la copia original, sin parches).
rem No borra las copias. No toca diccionarios.

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Se necesitan permisos de administrador. Reiniciando con elevacion...
    if "%~1"=="" (
        powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    ) else (
        powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -ArgumentList '\"%~1\"' -Verb RunAs"
    )
    exit /b
)

set "OO="
if not "%~1"=="" if exist "%~1\editors\sdkjs" set "OO=%~1"
if not defined OO if exist "%ProgramFiles%\ONLYOFFICE\DesktopEditors\editors\sdkjs" set "OO=%ProgramFiles%\ONLYOFFICE\DesktopEditors"
if not defined OO if exist "%ProgramFiles(x86)%\ONLYOFFICE\DesktopEditors\editors\sdkjs" set "OO=%ProgramFiles(x86)%\ONLYOFFICE\DesktopEditors"
if not defined OO if exist "%LOCALAPPDATA%\Programs\ONLYOFFICE\DesktopEditors\editors\sdkjs" set "OO=%LOCALAPPDATA%\Programs\ONLYOFFICE\DesktopEditors"
if not defined OO (
    echo No se encontro ONLYOFFICE Desktop Editors. Ejecuta: %~nx0 "C:\ruta\DesktopEditors"
    pause
    exit /b 1
)

echo Instalacion: %OO%
taskkill /f /im DesktopEditors.exe >nul 2>&1
taskkill /f /im editors.exe >nul 2>&1
taskkill /f /im editors_helper.exe >nul 2>&1
timeout /t 2 /nobreak >nul

set "N=0"
for /r "%OO%\editors\sdkjs" %%F in (*.bak_esAR) do (
    if /i "%%~nxF"=="sdk-all-min.js.bak_esAR" (
        copy /Y "%%F" "%%~dpnF" >nul && (echo   restaurado: %%~dpnF & set /a N+=1) || echo   ERROR al restaurar %%~dpnF
    )
)
echo.
echo Archivos restaurados: %N%
echo.
pause
exit /b 0
