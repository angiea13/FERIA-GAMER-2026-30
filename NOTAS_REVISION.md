# Notas de revisión – Feria Gamer 2026-30

> Todo esto se escribió sin poder abrir Godot, así que **abre el proyecto una vez y prueba**.
> Godot va a generar los `.uid` / `.import` nuevos solos. Si sale algún error rojo, mándamelo.

## 1. ¿El código va bien?
Lo que ya estaba bien: dash, salto de pared, coyote/jump buffer, telarañas con `sustitutos`, ataque con polígonos izquierda/derecha. Está bien organizado.

### Bugs que encontré (y ya corregí en esta copia)
| Dónde | Problema | Arreglo |
|---|---|---|
| `enemigo.gd` / espada | **La espada no podía dañar al enemigo**: el enemigo no estaba en el grupo `golpeable`, no tenía `recibir_golpe()`, y `Slash_Area` solo miraba la capa 1 (el enemigo está en la 2). | Grupo + `recibir_golpe()` + `Slash_Area.collision_mask = 2` |
| `enemigo.gd` | No tenía gravedad (flotaba), nunca atacaba (`iniciar_ataque()` no se llamaba y no hacía daño) y llamaba `_al_terminar_animacion()` en cada frame. | Reescrito: patrulla, ataque con daño en un frame, retroceso, muerte con fade |
| `Caballero_Enemy.tscn` | Los RayCast de borde terminaban 5 px **antes** de los pies, así que nunca tocaban el suelo y el enemigo se daba la vuelta cada frame. | Rayos reposicionados |
| `player.gd` | El jugador no podía recibir daño ni morir. | `recibir_dano()`, `matar()`, parpadeo, reinicio al morir |
| `player.gd` | `print("Detectó…")` en cada frame al deslizarse en pared. | Quitado |
| `player.gd` | Teletransporte "anterior" nunca reiniciaba su cooldown (`tiempo_teletransporte_ant`). | Corregido |
| `player.tscn` | `collision_mask = 3` hacía que los enemigos fueran muros sólidos para el jugador. | `collision_mask = 1` (si lo quieres sólido, vuelve a poner 3) |
| `Utils_Global.gd` | Guarda en `res://` (solo lectura al exportar) y **al cargar cualquier nivel te mueve a las coordenadas guardadas del nivel 1**. | Ahora guarda en `user://` y anota la escena |
| `Vida.gd` | `extends Node` pero nunca se agrega al árbol → fuga de memoria con cada `Vida.new()`. | `extends RefCounted` |
| `savegame.bin` | Estaba subido al repo. | Quitado y agregado al `.gitignore` |

### Pendiente / a revisar (no lo toqué)
- `player.gd`: tras caminar fuera de un borde, durante 0.2 s la caída se limita a 120 px/s (la condición `coyote_restante < COYOTE_TIEMPO and > 0` dentro del bloque de deslizamiento). Se siente "flotante"; probablemente no es intencional.
- `Enemigo.tscn` (Pig_Enemy) quedó obsoleto: no tiene animación "Movimiento". Usen `Caballero_Enemy.tscn`.
- El nodo `Armas` sigue dentro de `player.tscn` pero `player.gd` ya no lo usa; se puede borrar (junto con `armas.tscn` y `espada.png` cuando cambien la espada).
- `assets/world_tileset.png.import` está huérfano (no existe el .png) y `scripts/node_2d.tscn` es una escena vacía.
- `project.godot`: `window/size/initial_position=Vector2i(0,-460)` es de tu monitor; en otra PC la ventana puede salir fuera de pantalla.
- `level_1.tscn` tiene su TileSet **incrustado**; conviene cambiarlo a `resources/tileset_mundo.tres` para compartir uno solo.
- `level_1` no tiene `Meta`: ponle una con `siguiente_nivel = level_2.tscn`.

## 2. Tileset compartido
**Arte nuevo:** `assets/Mundo/tileset_telaranas.png` (512×384, tiles de 32×32, pixel art con la paleta del personaje: ladrillo morado oscuro, vetas rojas, hilos de telaraña colgando). Mantiene **el mismo orden de celdas** que el placeholder, así que se puede pintar igual.
**Configuración:** `resources/tileset_mundo.tres` usa ese PNG. Diferencias con el que estaba incrustado en level_1:
- Solo los tiles con píxeles tienen datos (antes había físicas en celdas vacías).
- Bloques sólidos con colisión; las **plataformas flotantes** (12‑15, 4) son *one-way*.
- **Pinchos** (4‑7, 10‑11): sin colisión, con dato personalizado `dano = 20` (los procesa `tilemap_peligros.gd`).
- Dos tiles nuevos: esquinas inferiores (0,8) y (1,8).
- Capa de física con `collision_layer = 3` (igual que antes: jugador y enemigos caminan sobre ella).

Receta rápida de pintado: techo del suelo = fila 0 (8,0 / 5‑6,0 / 15,0), relleno = (1‑2, 1‑2), bordes = (0,5‑6) y (7,5‑6), base = (9‑10,7), esquinas inferiores = (0,8) y (1,8), plataforma delgada = (12‑15,4) + (12‑15,5).
El `TileMapLayer` de los niveles tiene `texture_filter = Nearest` para que no se vea borroso. El PNG viejo (`placeholders_tile_set.png`) se queda porque level_1 lo sigue usando.

## 3. Niveles
`scenes/Niveles y Camara autoscroll/`
- `level_plantilla.tscn` – plantilla: suelo, un enemigo, meta, zona de muerte, jugador+cámara. Duplícala (Guardar como…) para cada nivel nuevo.
- `level_2.tscn` – pinchos, 5 enemigos y un cruce de ~1470 px con telarañas (E). Meta → nivel 3.
- `level_3.tscn` – escalón alto, torre de plataformas, cruce vertical con telaraña y enemigo guardando la meta. Meta → menú (`game.tscn`).

Medidas con las que diseñé (según tus constantes): salto ≈ 215 px (6.7 tiles), alcance horizontal ≈ 660 px. Máx. 5 tiles de subida y 14 de hueco.

Escenas nuevas: `World/meta.tscn`, `World/zona_muerte.tscn`.

⚠️ Los niveles **no** usan `level.tscn` (el piso infinito) porque con él no pueden existir huecos.
⚠️ Si cortan con la espada el hilo de la telaraña del cruce, hay que reintentar (caen y reaparecen).
