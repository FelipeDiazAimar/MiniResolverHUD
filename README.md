# MiniResolverHUD

Copias texto o imagen → OpenCode responde → la respuesta aparece abajo-izquierda, sin notificaciones.

## Que hace

- Vigilante del portapapeles: copias algo (`Ctrl+C`) y llega la respuesta al HUD al instante.
- Texto e imagenes (un recorte de `Win+Shift+S` queda en el portapapeles y va a vision).
- Conversacion continua mientras esta prendido (apagar y prender = conversacion nueva).
- HUD minimo: solo texto flotante abajo-izquierda, sin fondo. `Ctrl+B` muestra/oculta.
- `Ctrl+´` transparenta la letra, `Ctrl+{` la vuelve solida (teclado latino).
- Extension de Chrome opcional: oculta el resaltado azul en las paginas (el copiado sigue andando).

## Requisitos

- Windows 10/11 con PowerShell 5.1 (ya incluido).
- [OpenCode CLI](https://opencode.ai) con un modelo con vision. Default: `opencode-go/muse-spark-1.3-contributor` (se cambia con la variable `OPENCODE_MODEL`).
- Chrome solo si queres la extension.

## Instalacion

1. Clona o copia esta carpeta en `%USERPROFILE%\opencode-noti` (los `.bat` apuntan ahi; si la pones en otro lado, ajustalos).
2. Copia `QA-ON.bat` y `QA-OFF.bat` al Escritorio (o ejecutalos desde aca).
3. Extension (opcional): `chrome://extensions` → modo desarrollador → **Cargar descomprimida** → carpeta `chrome-sel`. Fija el icono y apreta **ACTIVAR**.

## Uso

1. Doble clic `QA-ON` → copia texto o imagen → respuesta al instante en el HUD.
2. Repetir la misma pregunta: copia otra cosa y volve a copiarla.
3. `QA-OFF` apaga todo (watcher + HUD).

## Archivos

| Archivo | Que es |
|---|---|
| `QA-ON.bat` / `QA-OFF.bat` | Prende/apaga (van en el Escritorio) |
| `qa-watcher.ps1` | Mira el portapapeles, consulta a opencode, guarda respuesta |
| `qa-hud.ps1` | Ventanita flotante con la respuesta |
| `kill-watcher.ps1` | Mata los procesos (lo usa `QA-OFF`) |
| `chrome-sel/` | Extension de Chrome (resaltado invisible) |

Log y estado: `%TEMP%\qa-watcher.log`, `%TEMP%\qa-hud.log`, `%TEMP%\qa-hud.txt`.
