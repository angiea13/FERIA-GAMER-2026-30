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
| 'player.gd'| Hice que el dash, lo volviera invulnerable por 0.2 segundos
| 'tunel_impulso.tscn'| Le hice una animacion de explosion y que desaparezca mientras tanto
| 'Lvl 1 que es el 3'| le agregue un fondo no se que tal les parezca
| 'Lvl 2' hice como q aparezca la tecla a revisar 
| CheckPoints| 
|Telarana| ahora parece q se mueve por la telarana todo bonito, se puede hacer eso similar para los enemigos
|Menu de Pausa| Un menu de pausa q funciona pero se ve feo
### Pendiente / a revisar (no lo toqué)
- `player.gd`: tras caminar fuera de un borde, durante 0.2 s la caída se limita a 120 px/s (la condición `coyote_restante < COYOTE_TIEMPO and > 0` dentro del bloque de deslizamiento). Se siente "flotante"; probablemente no es intencional. 
- `Enemigo.tscn` (Pig_Enemy) quedó obsoleto: no tiene animación "Movimiento". Usen `Caballero_Enemy.tscn`.
- El nodo `Armas` sigue dentro de `player.tscn` pero `player.gd` ya no lo usa; se puede borrar (junto con `armas.tscn` y `espada.png` cuando cambien la espada).
- `assets/world_tileset.png.import` está huérfano (no existe el .png) y `scripts/node_2d.tscn` es una escena vacía.
- `project.godot`: `window/size/initial_position=Vector2i(0,-460)` es de tu monitor; en otra PC la ventana puede salir fuera de pantalla.
- `level_1.tscn` tiene su TileSet **incrustado**; conviene cambiarlo a `resources/tileset_mundo.tres` para compartir uno solo.
- `level_1` no tiene `Meta`: ponle una con `siguiente_nivel = level_2.tscn`.
- 'camara', se debe definir bien como va a ser la camara en cada nivel porque es muy pequeba
- No me gusta como se ve la animacion en la telarana
- Menu de pausa se ve muy feo
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
## 4. Lo que hice después de "los niveles 2 y 3 y los tiles" (2–9 nov)

### Niveles
| Dónde | Qué hice |
|---|---|
| `level_1` (es el nivel 3) | Lo rehíce y le puse fondo con niebla (`fondo_niebla.png`, `fondo_loop_atenuado.png`) |
| `level_2` | Ahora aparece la tecla que hay que pulsar (`World/panel_container.tscn` + `panel_container.gd`) |
| `level_3` | Ajustes de diseño |
| `level_4` | Nivel nuevo |
| `level_5` | Nivel nuevo; después lo rediseñé con los tilesets nuevos y capas de detalle (`detalles.tres`, `detalles2.tres`, `detalles3.tres`, `Dano-q-mata.tres`) |
| `level_6` | Nivel nuevo, completo (con `level_6.gd`) |
| `level_7` | Nivel nuevo |
| `level_plantilla` | Actualizada |
| Checkpoints | `check_points.tscn` + `check_points.gd`: guardan la partida al pasar |
| Zona de muerte | Nueva `zona_muerte_chiquita` para huecos pequeños |

### Jugador
| Qué | Detalle |
|---|---|
| Doble salto | Agregado |
| Movimiento | Cambié cómo se mueve el jugador |
| Telaraña | Animación al entrar y al viajar (`Jugador/Entrar`, `Jugador/Viajar`) |
| Sonidos | Dash, saltos, aterrizar, deslizarse, salto de pared, correr, ataque, burbuja, telaraña y muerte |
| Combo | Ataque de 3 golpes (`atacando_2`, `atacando_3`, `combo_identico_hoja.png`) |
| Pared | Animación de deslizarse por la pared (`Jugador/deslizarse`) |
| Pinchos | Daño con tiles: `tile_maps_que_matan.gd` (mata) y `tilemap_peligros.gd` (quita vida) |

### Burbujas y telarañas
- Las burbujas tienen animación de explosión, desaparecen y reaparecen, y tienen sonido.
- Arreglé un bug de las burbujas con el dash (`tunel_impulso.gd`, `dash.gd`).
- Reescribí `telarana.gd`: el jugador viaja por el hilo.

### Menús y sonido
- Menú de pausa (`Menus/MenuPausa.tscn` + `menu_pausa.gd`). Funciona, pero se ve feo.
- Pantalla de carga nueva (`pantalla_carga_final.png` y versión morada).
- Configuraciones con **Volumen** (`Volumen.tscn` + `volumen.gd`, buses en `default_bus_layout.tres`) y **Controles** (`Controles.tscn` + `controles.gd`).
- Slider de volumen con estilo propio (`UI Menus/H_silider`).
- Música de fondo en los niveles (2 pistas en `Sonidos/Musica De Fondo`, `sonido_del_juego.tscn`).

### Arte
- Tilesets nuevos en `assets/Mundo/Tile_Sets/` (complementario, musgo, spritecook y telarañas). Moví ahí `tileset_telaranas.png`.

### Pendiente / a revisar sigue apuntando a la ruta vieja: el botón de Inicio no encuentra el nivel.
- El menú de pausa está dentro de `Fondo` (layer -10), así que en los niveles queda detrás de todo.
- `Detalles3` del nivel 5 tiene 41 355 tiles de 16 px; si algún día va lento en otra PC, hay que aligerarla.
- Hay que decidir el orden final de los niveles: `level_1` es en realidad el nivel 3.
⚠️ Los niveles **no** usan `level.tscn` (el piso infinito) porque con él no pueden existir huecos.
⚠️ Si cortan con la espada el hilo de la telaraña del cruce, hay que reintentar (caen y reaparecen).
###Bugs que se encontro y no se han revisado
tunel_impulso.gd: con velocidad_impulso = 10 y el dash activo, el juego da error al tocar la burbuja. Asignas un número a velocity en lugar de un vector. Debería ser direccion * cuerpo.velocity.length() * 1.2.
Mismo caso: el dash vuelve a poner su velocidad al frame siguiente y se pierde el cambio de dirección. Hay que terminar el dash al tocar la burbuja.
volumen.gd: el segundo slider usa el bus "EFECTOS", que no existe. Tus buses son Master, SFX y New Bus.
Volumen.tscn: HSlider2 está conectado a los dos métodos, así que también cambia SFX.
Volumen: al volver al menú, los sliders no muestran el volumen actual.
level_plantilla.tscn: se instancia a sí misma y no se puede abrir.
dash.gd: un dash viejo puede cortar al nuevo si encadenas dashes, por ejemplo con una burbuja.
player.gd: los golpes 2 y 3 del combo usan la duración del primero.
