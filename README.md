# ONLYOFFICE Desktop Editors: corrector ortográfico para Español (Argentina)

Parche para que el corrector ortográfico automático de **ONLYOFFICE Desktop Editors (Windows)** funcione con el idioma **Español (Argentina)**.

Sin este parche, al elegir «Español (Argentina)» el idioma aparece sin la marca **A** (corrector no disponible) y no se subraya ninguna palabra incorrecta, mientras que con «Español (España)» sí funciona.

> Probado en ONLYOFFICE Desktop Editors **10.0.0.169** sobre Windows. En otras versiones puede funcionar o no: el script se detiene sin modificar nada si no reconoce el código que espera.

## Contenido

| Archivo | Qué hace |
|---|---|
| `onlyoffice_es_AR_v3.bat` | Aplica el parche. |
| `onlyoffice_es_AR_revertir.bat` | Deshace el parche y restaura los archivos originales. |

## Uso

1. **Cerrá ONLYOFFICE.** El script también intenta cerrarlo.
2. Ejecutá `onlyoffice_es_AR_v3.bat` con doble clic. Pide permisos de administrador porque modifica archivos dentro de `Program Files`.
3. Abrí ONLYOFFICE, elegí «Español (Argentina)» como idioma del texto y escribí una palabra mal para comprobarlo.
4. Si hace falta, activá el corrector en *Archivo → Configuración avanzada*.

Si ONLYOFFICE no está en una ruta habitual (`Program Files`, `Program Files (x86)` o `%LOCALAPPDATA%\Programs`), pasá la carpeta como argumento:

```bat
onlyoffice_es_AR_v3.bat "D:\Apps\ONLYOFFICE\DesktopEditors"
```

### Revertir

Ejecutá `onlyoffice_es_AR_revertir.bat`. Restaura cada `sdk-all-min.js` desde su copia `.bak_esAR` y no borra las copias.

### Después de actualizar ONLYOFFICE

Las actualizaciones reemplazan los archivos del SDK y el parche se pierde. Volvé a ejecutar `onlyoffice_es_AR_v3.bat`.

## Por qué ocurre

En la versión de escritorio, el corrector no lo hace el código JavaScript del editor sino un **motor nativo compilado dentro del programa**. Ese motor trae una tabla fija que une cada código de idioma de Windows con una carpeta de `dictionaries/`. Para español tiene una sola entrada: `es_ES` con el código `3082` (España). No existe una entrada para `11274` (Argentina).

Por eso fallan los intentos habituales:

- Copiar `es_ES` como `es_AR` no sirve: el motor nunca busca esa carpeta.
- Crear un `es_AR.json` con el código `11274` tampoco: esos `.json` solo los lee `generate.py` cuando ONLYOFFICE compila el programa, no en tiempo de ejecución.
- Agregar `11274` a `spellcheckGetLanguages()` en el SDK solo hace aparecer la marca **A**, pero el motor sigue sin reconocer el código.

Código fuente relacionado:

- [`desktop-sdk/ChromiumBasedEditors/lib/src/spellchecker.cpp`](https://github.com/ONLYOFFICE/desktop-sdk/blob/master/ChromiumBasedEditors/lib/src/spellchecker.cpp): `SetLanguage()` y `Init()`.
- [`core/Common/3dParty/hunspell/autogen/`](https://github.com/ONLYOFFICE/core/tree/master/Common/3dParty/hunspell/autogen): `generate.py` y `records.h`.

## Qué modifica el parche

No toca ningún `.exe` ni `.dll`. Modifica únicamente los archivos `editors/sdkjs/*/sdk-all-min.js` (word, cell, slide y los demás que encuentre) en dos puntos:

1. **Tabla de idiomas con corrector.** Agrega `11274:{hyphen:!0,name:"es_ES"}` a `spellcheckGetLanguages()`, para que «Español (Argentina)» figure con corrector (la **A**).
2. **Pedido al motor nativo.** En la llamada `AscDesktopEditor.SpellCheck(JSON.stringify(...))`, reemplaza `11274` por `3082` solo dentro de la lista `"usrLang"`. El motor corrige entonces con el diccionario `es_ES` que ya viene instalado.

Detalles de seguridad del script:

- Valida **todos** los archivos antes de escribir. Si alguno no se reconoce, cancela sin modificar nada.
- Guarda una copia `.bak_esAR` de cada archivo y **no la pisa** si ya existe, así que conserva el original aunque lo ejecutes varias veces.
- Relee cada archivo tras escribirlo y, si algo falla, restaura lo escrito en esa ejecución.
- Es idempotente: ejecutarlo dos veces no duplica el cambio.

## Requisitos

- Windows con ONLYOFFICE Desktop Editors instalado.
- Permisos de administrador (si ONLYOFFICE está en `Program Files`).
- PowerShell, que viene con Windows. Se usa solo para reemplazar texto dentro de los archivos minificados.
- El diccionario `dictionaries\es_ES` instalado de serie.

## Limitaciones

- El corrector usa el diccionario de **español de España**. Marcará como error el voseo («tenés», «querés»).
- Es una modificación de archivos de la instalación, no una función oficial de ONLYOFFICE.
- Si una versión futura trae el soporte de es-AR de serie, este parche deja de ser necesario. En ese caso, ejecutá el BAT de revertir.
- Si ONLYOFFICE cambia el texto de su SDK, el script lo avisa y no modifica nada. Abrí un *issue* con el mensaje que muestra.

## Aviso

Este proyecto no está afiliado a ONLYOFFICE ni a Ascensio System SIA. Se entrega tal cual, sin garantías. Los parches modifican archivos de tu instalación: leé los scripts antes de ejecutarlos. Los diccionarios que usa vienen con ONLYOFFICE y conservan sus propias licencias.

## Licencia

Elegí la licencia del repositorio (por ejemplo MIT) y agregá el archivo `LICENSE`.
