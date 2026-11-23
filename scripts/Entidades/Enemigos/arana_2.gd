class_name Enemigo2
extends CharacterBody2D
## Araña: si te ve de lejos se lanza con un DASH (su ataque principal).
## Si estás pegado a ella, MUERDE. Si el dash no está listo, te PERSIGUE.
## Con poca vida, se glitchea y suelta un diálogo (invulnerable mientras habla).
## Al terminar el diálogo, deja de atacar para siempre pero sigue siendo matable.
## Al morir: fade del sprite + fundido a negro de pantalla completa, luego emite "murio".
## Animaciones: "Movimiento" (en bucle), "Ataque", "Dash", "Golpeado", "Muerte" (sin bucle).

enum Estado { PATRULLA, ALERTA, PERSEGUIR, DASH, MORDIDA, RECUPERAR, GOLPEADO, DIALOGO, MUERTO }

@export_group("General")
@export var vida_maxima := 5
@export var dano := 20                       # daño de la mordida
@export var dano_dash := 25                  # daño al caerte encima con el dash
@export var retroceso_golpe := 350.0
@export var empieza_mirando_derecha := true
@export var sprite_mira_derecha := true      # desmárcalo si el dibujo original mira a la izquierda
@export var capa_jugador := 1                # capa de colisión en la que está el jugador
@export var depurar := true                  # escribe en la Salida lo que piensa

@export_group("Movimiento")
@export var velocidad_patrulla := 90.0
@export var velocidad_persecucion := 220.0
@export var aceleracion := 1400.0            # más alto = arranca más rápido
@export var friccion := 1800.0               # más alto = frena más rápido

@export_group("Visión")
@export var rango_vision := 900.0            # a esta distancia te ve
@export var rango_perder := 1300.0           # si te alejas más, te olvida
@export var altura_max := 300.0              # diferencia de altura máxima para verte
@export var tiempo_alerta := 0.25            # pausa breve al verte

@export_group("Mordida (cerca)")
@export var rango_mordida := 40.0            # distancia extra desde el borde de su cuerpo
@export var frame_golpe := 3                 # frame de "Ataque" en el que pega
@export var impulso_mordida := 260.0
@export var zona_ataque_tamano := Vector2(140, 110)
@export var zona_ataque_distancia := 80.0
@export var recuperacion_mordida := 0.5

@export_group("Dash (lejos, ataque principal)")
@export var puede_dash := true
@export var dash_distancia_min := 10.0      # más cerca que esto no hace dash
@export var dash_distancia_max := 900.0
@export var tiempo_carga := 0.35             # tiempo agazapada antes de saltar (aviso al jugador)
@export var salto_dash := 380.0              # fuerza vertical del salto
@export var velocidad_dash_max := 750.0
@export var enfriamiento_dash := 1.6
@export var recuperacion_dash := 0.45
@export var frame_carga := 1                 # frame de "Dash" en que se queda agazapada
@export var frame_despegue := 2
@export var frame_aire_fin := 4              # pose de vuelo: se congela hasta tocar el suelo

@export_group("Diálogo (vida baja)")
@export var umbral_dialogo: int = 15
@export var lines: Array[String] = [""]
@export var glitch_duration: float = 20.0    # segundos de diálogo hasta el glitch máximo
@export_range(0.0, 1.0) var glitch_max: float = 1.0
@export_group("")

@export_group("Muerte")
@export var fundido_duracion: float = 1.0
@export_group("")

var estado := Estado.PATRULLA
var vida: Vida
var direccion := 1
var jugador: Jugador
var zona_dano: Area2D
var muerto := false
var temporizador := 0.0
var cd_dash := 0.0
var cd_giro := 0.0
var ya_pego := false
var impulso_dado := false
var despego := false
var aterrizo := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: CollisionShape2D = $Hitbox
@onready var ray_derecha: RayCast2D = $Derecha
@onready var ray_izquierda: RayCast2D = $Izquierda
@onready var dialog_bubble = $BurbujaDialogo

signal usado
signal murio
signal fin_dialogo    # se emite cuando termina el diálogo de vida baja, si sobrevive

@export var fade_in: float = 2.0

var activo := false
var jugador_cerca := false
var congelado := false

var _layer_guardada := 0
var _mask_guardada := 0

# --- Diálogo / glitch de vida baja ---
var ya_glitcheo := false
var dialog_active := false
var current_line := 0
var glitch_time := 0.0
var glitch_mat: ShaderMaterial

# --- Pacífica (tras el diálogo, ya no ataca, pero sigue siendo matable) ---
var pacifico := false


func _ready() -> void:
	vida = Vida.new(vida_maxima)
	add_to_group("golpeable")
	add_to_group("enemigos")
	direccion = 1 if empieza_mirando_derecha else -1
	sprite.animation_finished.connect(_al_terminar_animacion)
	_crear_zona_dano()
	_orientar()

	dialog_bubble.visible = false
	dialog_bubble.line_finished.connect(_on_line_finished)

	if sprite.material is ShaderMaterial:
		# duplicate() para que esta araña tenga su propia intensidad de glitch
		glitch_mat = sprite.material.duplicate()
		sprite.material = glitch_mat
	else:
		push_warning("Arana_2: el AnimatedSprite2D no tiene un ShaderMaterial para el glitch.")

	_layer_guardada = collision_layer
	_mask_guardada = collision_mask
	_desactivar()


func _desactivar() -> void:
	activo = false
	visible = false
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	hitbox.set_deferred("disabled", true)
	zona_dano.monitoring = false
	sprite.modulate.a = 0.0


func activar() -> void:
	if activo:
		return
	activo = true
	visible = true
	collision_layer = _layer_guardada
	collision_mask = _mask_guardada
	hitbox.set_deferred("disabled", false)
	zona_dano.monitoring = true
	set_physics_process(true)

	sprite.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(sprite, "modulate:a", 1.0, fade_in)


func _crear_zona_dano() -> void:
	zona_dano = Area2D.new()
	zona_dano.collision_layer = 0
	zona_dano.collision_mask = 0
	zona_dano.set_collision_mask_value(capa_jugador, true)
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = zona_ataque_tamano
	forma.shape = rect
	zona_dano.add_child(forma)
	zona_dano.position = Vector2(direccion * zona_ataque_distancia, hitbox.position.y)
	add_child(zona_dano)


func _input(event: InputEvent) -> void:
	if dialog_active and event.is_action_pressed("interact"):
		dialog_bubble.advance()


func _process(delta: float) -> void:
	# Solo se distorsiona mientras hay diálogo activo
	if not dialog_active or glitch_mat == null:
		return
	glitch_time += delta
	var t := clampf(glitch_time / glitch_duration, 0.0, 1.0)
	glitch_mat.set_shader_parameter("intensity", t * t * glitch_max)


func _physics_process(delta: float) -> void:
	if estado == Estado.MUERTO:
		return

	if congelado or estado == Estado.DIALOGO:
		if not is_on_floor():
			velocity += get_gravity() * delta
		velocity.x = move_toward(velocity.x, 0.0, friccion * delta)
		move_and_slide()
		return

	if not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador") as Jugador

	temporizador -= delta
	cd_dash = maxf(cd_dash - delta, 0.0)
	cd_giro = maxf(cd_giro - delta, 0.0)

	if not is_on_floor():
		velocity += get_gravity() * delta

	match estado:
		Estado.PATRULLA: _estado_patrulla(delta)
		Estado.ALERTA: _estado_alerta(delta)
		Estado.PERSEGUIR: _estado_perseguir(delta)
		Estado.DASH: _estado_dash(delta)
		Estado.MORDIDA: _estado_mordida(delta)
		Estado.RECUPERAR: _estado_recuperar(delta)
		Estado.GOLPEADO: _estado_golpeado(delta)

	move_and_slide()

	if depurar and Engine.get_physics_frames() % 30 == 0:
		_imprimir_estado()


#Estados Posibles
func _estado_patrulla(delta: float) -> void:
	_animar("Movimiento")
	if _ve_al_jugador(rango_vision):
		_cambiar(Estado.ALERTA)
		temporizador = tiempo_alerta
		return
	if is_on_floor() and cd_giro <= 0.0 and (not _hay_suelo_delante() or is_on_wall()):
		_girar()
	_mover_hacia(velocidad_patrulla * direccion, delta)


func _estado_alerta(delta: float) -> void:
	_frenar(delta)
	_mirar_al_jugador()
	if temporizador <= 0.0:
		if not _elegir_ataque():
			_cambiar(Estado.PERSEGUIR)


func _estado_perseguir(delta: float) -> void:
	if not _ve_al_jugador(rango_perder):
		_cambiar(Estado.PATRULLA)
		return
	_mirar_al_jugador()
	if _elegir_ataque():
		return
	_animar("Movimiento")
	var objetivo := velocidad_persecucion * direccion
	if is_on_floor() and not _hay_suelo_delante():
		objetivo = 0.0
	_mover_hacia(objetivo, delta)


func _estado_dash(delta: float) -> void:
	if not despego:
		_frenar(delta)
		_mirar_al_jugador()
		if sprite.frame >= frame_carga and sprite.is_playing():
			sprite.pause()
		if temporizador <= 0.0:
			_despegar()
		return

	if not aterrizo:
		if sprite.frame >= frame_aire_fin and sprite.is_playing():
			sprite.pause()
		_pegar_si_toca(dano_dash)
		if is_on_floor() and temporizador <= 0.0:
			aterrizo = true
			temporizador = 0.3
			sprite.play()
		return

	_frenar(delta)
	_pegar_si_toca(dano_dash)
	if temporizador <= 0.0:
		if _jugador_cerca():
			_empezar_mordida()
		else:
			_empezar_recuperar(recuperacion_dash)


func _estado_mordida(delta: float) -> void:
	if sprite.frame < frame_golpe:
		_mirar_al_jugador()
		if not _jugador_en_zona() and _hay_suelo_delante():
			_mover_hacia(velocidad_persecucion * 0.6 * direccion, delta)
		else:
			_frenar(delta)
	else:
		if not impulso_dado:
			impulso_dado = true
			if _hay_suelo_delante():
				velocity.x = impulso_mordida * direccion
		else:
			_frenar(delta)
		_pegar_si_toca(dano)
	if temporizador <= 0.0:
		_empezar_recuperar(recuperacion_mordida)


func _estado_recuperar(delta: float) -> void:
	_frenar(delta)
	_mirar_al_jugador()
	if temporizador <= 0.0:
		if _ve_al_jugador(rango_perder):
			if not _elegir_ataque():
				_cambiar(Estado.PERSEGUIR)
		else:
			_cambiar(Estado.PATRULLA)


func _estado_golpeado(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
	if temporizador <= 0.0:
		_cambiar(Estado.PERSEGUIR)


#Que puede decidir
func _elegir_ataque() -> bool:
	if pacifico or jugador == null:
		return false
	var dist := absf(_dx())
	if _dash_listo() and dist >= dash_distancia_min and dist <= dash_distancia_max:
		_empezar_dash()
		return true
	if _jugador_cerca():
		_empezar_mordida()
		return true
	return false


func _empezar_mordida() -> void:
	_cambiar(Estado.MORDIDA)
	ya_pego = false
	impulso_dado = false
	temporizador = 2.0
	_mirar_al_jugador()
	sprite.play("Ataque")
	sprite.frame = 0


func _empezar_dash() -> void:
	_cambiar(Estado.DASH)
	despego = false
	aterrizo = false
	ya_pego = false
	temporizador = tiempo_carga
	cd_dash = enfriamiento_dash
	_mirar_al_jugador()
	sprite.play("Dash")
	sprite.frame = 0


func _despegar() -> void:
	despego = true
	temporizador = 0.1
	sprite.play("Dash")
	sprite.frame = frame_despegue
	var g := maxf(get_gravity().y, 1.0)
	var t_aire := 2.0 * salto_dash / g
	var dx := _dx()
	if jugador:
		dx += jugador.velocity.x * t_aire * 0.5
	var vx := clampf(dx / t_aire, -velocidad_dash_max, velocidad_dash_max)
	if absf(vx) > 1.0:
		direccion = 1 if vx > 0.0 else -1
		_orientar()
	velocity = Vector2(vx, -salto_dash)


func _empezar_recuperar(tiempo: float) -> void:
	_cambiar(Estado.RECUPERAR)
	temporizador = tiempo
	sprite.play("Movimiento")
	sprite.pause()

#Que cosas puede hacer
func _cambiar(nuevo: Estado) -> void:
	estado = nuevo
	if not sprite.is_playing():
		sprite.play()


func _animar(nombre: String) -> void:
	if sprite.animation != nombre or not sprite.is_playing():
		sprite.play(nombre)


func _mover_hacia(objetivo: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, objetivo, aceleracion * delta)


func _frenar(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friccion * delta)


func _dx() -> float:
	return jugador.global_position.x - global_position.x if jugador else 0.0


func _ve_al_jugador(rango: float) -> bool:
	if jugador == null:
		return false
	var d := jugador.global_position - global_position
	return absf(d.x) < rango and absf(d.y) < altura_max


func _medio_ancho() -> float:
	var w := 20.0
	var s := hitbox.shape
	if s is RectangleShape2D:
		w = s.size.x * 0.5
	elif s is CapsuleShape2D or s is CircleShape2D:
		w = s.radius
	return w * absf(hitbox.global_scale.x)


func _jugador_cerca() -> bool:
	if jugador == null:
		return false
	if _jugador_en_zona():
		return true
	var d := jugador.global_position - global_position
	return absf(d.x) <= _medio_ancho() + rango_mordida + 20.0 and absf(d.y) < altura_max * 0.5


func _jugador_en_zona() -> bool:
	for cuerpo in zona_dano.get_overlapping_bodies():
		if cuerpo is Jugador:
			return true
	return false


func _pegar_si_toca(cantidad: int) -> void:
	if pacifico or ya_pego:
		return
	for cuerpo in zona_dano.get_overlapping_bodies():
		if cuerpo is Jugador:
			cuerpo.recibir_dano(cantidad, global_position.x)
			ya_pego = true
			return


func _dash_listo() -> bool:
	return puede_dash and cd_dash <= 0.0 and is_on_floor() \
		and sprite.sprite_frames.has_animation("Dash")


func _hay_suelo_delante() -> bool:
	if is_on_floor() and not ray_derecha.is_colliding() and not ray_izquierda.is_colliding():
		return true
	var rayo := ray_derecha if direccion == 1 else ray_izquierda
	return rayo.is_colliding()


func _mirar_al_jugador() -> void:
	if jugador == null:
		return
	var dx := _dx()
	if absf(dx) < 8.0:
		return
	var quiere := 1 if dx > 0.0 else -1
	if quiere != direccion:
		_girar()


func _girar() -> void:
	direccion *= -1
	_orientar()
	cd_giro = 0.3


func _orientar() -> void:
	sprite.flip_h = (direccion > 0) != sprite_mira_derecha
	if zona_dano:
		zona_dano.position.x = direccion * zona_ataque_distancia


func _al_terminar_animacion() -> void:
	if estado == Estado.MORDIDA and sprite.animation == "Ataque":
		_empezar_recuperar(recuperacion_mordida)

#Para revisar bugs
func _imprimir_estado() -> void:
	var txt := "[%s] %s" % [name, Estado.keys()[estado]]
	if jugador == null:
		txt += " | NO encuentra al jugador (grupo 'jugador' + class_name Jugador)"
	else:
		var d := jugador.global_position - global_position
		txt += " | dist X=%d Y=%d | cerca=%s en_zona=%s | dash_listo=%s cd=%.1f | suelo=%s" % [
			int(d.x), int(d.y), _jugador_cerca(), _jugador_en_zona(), _dash_listo(), cd_dash, is_on_floor()]
	#print(txt)

#Dano
func recibir_golpe(dir: Vector2, cantidad: int) -> void:
	if estado == Estado.MUERTO or estado == Estado.DIALOGO:
		return    # invulnerable mientras habla: el jugador está obligado a escuchar
	vida._recibir_dano(cantidad)
	sprite.self_modulate = Color(1.0, 0.35, 0.35)
	create_tween().tween_property(sprite, "self_modulate", Color.WHITE, 0.25)
	if vida.muerte:
		_morir()
		return

	if not ya_glitcheo and vida.vida <= umbral_dialogo:
		ya_glitcheo = true
		_entrar_modo_dialogo()
		return

	_cambiar(Estado.GOLPEADO)
	temporizador = 0.35
	velocity = Vector2(dir.x * retroceso_golpe, -200.0)
	sprite.play("Golpeado")


func _entrar_modo_dialogo() -> void:
	_cambiar(Estado.DIALOGO)
	dialog_active = true
	current_line = 0
	glitch_time = 0.0
	velocity = Vector2.ZERO
	sprite.play("Movimiento")
	sprite.pause()
	get_tree().call_group("enemigos", "set", "congelado", true)
	if jugador:
		jugador.in_dialog = true
	dialog_bubble.visible = true
	dialog_bubble.show_dialog(lines[current_line])


func _on_line_finished() -> void:
	current_line += 1
	if current_line < lines.size():
		dialog_bubble.show_dialog(lines[current_line])
	else:
		_salir_modo_dialogo()


func _salir_modo_dialogo() -> void:
	dialog_active = false
	dialog_bubble.visible = false
	if jugador:
		jugador.in_dialog = false

	get_tree().call_group("enemigos", "set", "congelado", false)   # descongela a los demás

	pacifico = true
	zona_dano.monitoring = false
	estado = Estado.PATRULLA     # sale de DIALOGO -> ya puede recibir daño y morir
	congelado = true             # pero queda fija en idle, nunca más se mueve ni ataca
	sprite.play("Movimiento")
	sprite.pause()

	fin_dialogo.emit()


func morir() -> void:
	_morir()


func _morir() -> void:
	if muerto:
		return
	estado = Estado.MUERTO
	muerto = true
	remove_from_group("golpeable")
	hitbox.set_deferred("disabled", true)
	zona_dano.set_deferred("monitoring", false)
	velocity = Vector2.ZERO
	sprite.play("Muerte")
	await sprite.animation_finished

	var t := create_tween()
	t.tween_property(sprite, "modulate:a", 0.0, 0.5)
	await t.finished

	await _fundido_negro(fundido_duracion)

	murio.emit()   # con la pantalla ya en negro, level_9.gd cambia de escena


func _fundido_negro(duracion: float) -> void:
	var capa := CanvasLayer.new()
	capa.layer = 100                       # por encima de todo, incluida la UI
	var negro := ColorRect.new()
	negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	negro.color = Color(0, 0, 0, 0)         # negro, pero invisible al inicio
	capa.add_child(negro)
	get_tree().root.add_child(capa)         # cuelga de root, sigue en pantalla durante el change_scene_to_file

	var t := create_tween()
	t.tween_property(negro, "color:a", 1.0, duracion)
	await t.finished
