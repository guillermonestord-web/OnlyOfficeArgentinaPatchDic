@echo off
setlocal EnableExtensions
title ONLYOFFICE - Corrector ortografico Espanol (Argentina) v3

rem ==========================================================================
rem  ONLYOFFICE Desktop Editors 10.x - corrector para Espanol (Argentina)
rem
rem  En el programa de escritorio el motor de ortografia es NATIVO (compilado en
rem  el .exe) y solo conoce el codigo 3082 (Espanol-Espana). Este parche NO toca
rem  ningun .exe/.dll: modifica los sdk-all-min.js para que
rem    1) Espanol (Argentina) = 11274 figure con corrector (la "A"), y
rem    2) al pedir la correccion, el codigo 11274 se envie al motor como 3082,
rem       usando el diccionario es_ES que ya viene instalado.
rem
rem  Hace copia .bak_esAR de cada archivo (si ya existe, no la pisa).
rem  Para deshacer: onlyoffice_es_AR_revertir.bat
rem  Si actualizas ONLYOFFICE, volve a ejecutar este .bat.
rem  Uso: doble clic (pide administrador). Opcional: pasar la carpeta de instalacion.
rem ==========================================================================

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
set "OO_DIR=%OO%"
echo Instalacion: %OO%
echo.

echo Cerrando ONLYOFFICE...
taskkill /f /im DesktopEditors.exe >nul 2>&1
taskkill /f /im editors.exe >nul 2>&1
taskkill /f /im editors_helper.exe >nul 2>&1
timeout /t 2 /nobreak >nul

set "PSF=%TEMP%\oo_esAR_patch_v3.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Content -LiteralPath '%~f0' | Where-Object { $_.StartsWith('#PS#') } | ForEach-Object { $_.Substring(4) } | Set-Content -Encoding UTF8 -LiteralPath '%PSF%'"
powershell -NoProfile -ExecutionPolicy Bypass -File "%PSF%"
set "RC=%errorlevel%"
del "%PSF%" >nul 2>&1

echo.
if "%RC%"=="0" (
    echo LISTO. Abri ONLYOFFICE, elegi "Espanol (Argentina)" y escribi una palabra mal.
    echo Si hace falta, activa el corrector en Archivo ^> Configuracion avanzada.
) else (
    echo TERMINO CON ERRORES. No se modifico ningun archivo si el error fue de validacion.
)
echo.
pause
exit /b %RC%

rem ---- Desde aqui, solo PowerShell (lineas con prefijo #PS#). cmd nunca llega aca ----
#PS#$ErrorActionPreference = 'Stop'
#PS#$oo   = $env:OO_DIR
#PS#$utf8 = New-Object System.Text.UTF8Encoding($false)
#PS#
#PS#if (-not (Test-Path (Join-Path $oo 'dictionaries\es_ES\es_ES.dic'))) { Write-Host 'ERROR: no existe dictionaries\es_ES\es_ES.dic'; exit 1 }
#PS#
#PS## Parte 1: tabla de idiomas con corrector (para que aparezca la "A")
#PS#$entry      = '11274:{hyphen:!0,name:"es_ES"},'
#PS#$reExisting = New-Object System.Text.RegularExpressions.Regex('11274:\{hyphen:![01],name:"[A-Za-z_]+"\},')
#PS#$reTable    = New-Object System.Text.RegularExpressions.Regex('(window\.AscCommon\.spellcheckGetLanguages\s*=\s*function\s*\(\)\s*\{\s*return\s*\{)')
#PS#
#PS## Parte 2: traducir 11274 -> 3082 en el pedido que va al motor nativo
#PS#$reCall = New-Object System.Text.RegularExpressions.Regex('AscDesktopEditor\.SpellCheck\(JSON\.stringify\((\w+)\)\)')
#PS#$newCall = 'AscDesktopEditor.SpellCheck(JSON.stringify(${1}).replace(/("usrLang":\[)([^\]]*)/g,function(m,p,q){return p+q.replace(/\b11274\b/g,"3082")}))'
#PS#$callTag = 'q.replace(/\b11274\b/g,"3082")'
#PS#
#PS#$files = @(Get-ChildItem (Join-Path $oo 'editors\sdkjs') -Recurse -File | Where-Object { $_.Name -eq 'sdk-all-min.js' })
#PS#if ($files.Count -eq 0) { Write-Host 'ERROR: no se encontraron sdk-all-min.js'; exit 1 }
#PS#
#PS#Write-Host '[1/2] Validando (no se escribe nada todavia)'
#PS#$plan = @()
#PS#$bad = 0
#PS#foreach ($f in $files) {
#PS#    $rel = $f.FullName.Substring($oo.Length)
#PS#    $t = $utf8.GetString([IO.File]::ReadAllBytes($f.FullName))
#PS#    $new = $t
#PS#    if (-not $new.Contains($entry)) {
#PS#        if ($reExisting.IsMatch($new)) { $new = $reExisting.Replace($new, $entry, 1) }
#PS#        elseif ($reTable.IsMatch($new)) { $new = $reTable.Replace($new, ('${1}' + $entry), 1) }
#PS#        else { Write-Host ('  NO se reconoce la tabla de idiomas en ' + $rel); $bad++; continue }
#PS#    }
#PS#    if (-not $new.Contains($callTag)) {
#PS#        $n = $reCall.Matches($new).Count
#PS#        if ($n -lt 1) { Write-Host ('  NO se encontro SpellCheck(JSON.stringify(..)) en ' + $rel); $bad++; continue }
#PS#        $new = $reCall.Replace($new, $newCall)
#PS#    }
#PS#    if ($new -eq $t) { Write-Host ('  ya parcheado: ' + $rel); continue }
#PS#    $plan += [pscustomobject]@{ File = $f.FullName; Rel = $rel; Old = $t; New = $new }
#PS#    Write-Host ('  listo para parchear: ' + $rel)
#PS#}
#PS#if ($bad -gt 0) { Write-Host 'Se cancelo: no se modifico ningun archivo.'; exit 1 }
#PS#
#PS#Write-Host '[2/2] Aplicando'
#PS#$written = @()
#PS#try {
#PS#    foreach ($p in $plan) {
#PS#        $bak = $p.File + '.bak_esAR'
#PS#        if (-not (Test-Path $bak)) { [IO.File]::WriteAllBytes($bak, $utf8.GetBytes($p.Old)) }
#PS#        [IO.File]::WriteAllBytes($p.File, $utf8.GetBytes($p.New))
#PS#        $written += $p
#PS#        $chk = $utf8.GetString([IO.File]::ReadAllBytes($p.File))
#PS#        if (-not ($chk.Contains($entry) -and $chk.Contains($callTag))) { throw ('fallo la verificacion en ' + $p.Rel) }
#PS#        Write-Host ('  parcheado: ' + $p.Rel)
#PS#    }
#PS#} catch {
#PS#    Write-Host ('ERROR: ' + $_.Exception.Message + ' - restaurando lo escrito en esta ejecucion...')
#PS#    foreach ($p in $written) { [IO.File]::WriteAllBytes($p.File, $utf8.GetBytes($p.Old)); Write-Host ('  restaurado: ' + $p.Rel) }
#PS#    exit 1
#PS#}
#PS#exit 0
