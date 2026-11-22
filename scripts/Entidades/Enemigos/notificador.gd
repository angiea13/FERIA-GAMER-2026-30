class_name Notificador
extends CharacterBody2D

enum Estado { PATRULLA, ACOSO, PULSO, RETIRADA, GOLPEADO, MUERTO }

@export_group("Vida")
@export var vida_maxima := 2
@export var retroceso_golpe := 450.0

@export_group("Movimiento")
@export var velocidad_patrulla := 90.0
@export var velocidad_acoso := 190.0
@export var radio_patrulla := Vector2(150.0, 70.0)
@export var distancia_acoso := 240.0
@export var aceleracion := 5.0

@export_group("Detección")
@export var radio_deteccion := 560.0
@export var radio_soltar := 900.0

@export_group("Pulso de sonido")
@export var intervalo_pulso := 2.6
@export var tiempo_carga := 0.45
@export var radio_pulso := 340.0
@export var duracion_onda := 0.7
@export var duracion_hud_pulso := 1.3

@export_group("Contacto")
@export var duracion_aturdimiento := 0.8
@export var duracion_hud_contacto := 2.5
@export var dano := 0
@export var tiempo_retirada := 1.4

const COLOR_NUCLEO := Color("#FFE9A8")
const COLOR_HALO := Color("#FFD66B")
const COLOR_INSIGNIA := Color("#E5484D")

var estado := Estado.PATRULLA
var vida: Vida
var jugador: Jugador
var punto_base: Vector2
var tiempo := 0.0
var fase := 0.0
var angulo_orbita := 0.0
var temporizador_pulso := 0.0
var temporizador_estado := 0.0
var enfriamiento_contacto := 0.0
var onda_t := -1.0
var onda_ya_golpeo := false
var congelado = false

var glow: Sprite2D
var sonido_pulso: AudioStreamPlayer2D
var sonido_contacto: AudioStreamPlayer2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: CollisionShape2D = $Hitbox
@onready var zona_contacto: Area2D = $ZonaContacto


func _ready() -> void:
	vida = Vida.new(vida_maxima)
	add_to_group("golpeable")
	add_to_group("enemigos")
	add_to_group("notificadores")
	punto_base = global_position
	fase = randf() * TAU
	angulo_orbita = randf() * TAU
	temporizador_pulso = intervalo_pulso * randf_range(0.5, 1.0)
	sprite.animation_finished.connect(_al_terminar_animacion)
	sprite.play("vuelo")
	_crear_brillo()
	_crear_sonidos()


func _crear_brillo() -> void:
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(COLOR_HALO, 0.55), Color(COLOR_HALO, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	glow = Sprite2D.new()
	glow.texture = tex
	glow.scale = Vector2(2.4, 2.4)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	glow.show_behind_parent = true
	add_child(glow)


func _crear_sonidos() -> void:
	sonido_pulso = _nuevo_sonido("res://assets/Sonidos/Enemigos/notificador_pulso.wav", -4.0)
	sonido_contacto = _nuevo_sonido("res://assets/Sonidos/Enemigos/notificador_contacto.wav", -2.0)


func _nuevo_sonido(ruta: String, db: float) -> AudioStreamPlayer2D:
	var p := AudioStreamPlayer2D.new()
	if ResourceLoader.exists(ruta):
		p.stream = load(ruta)
	p.volume_db = db
	p.max_distance = 1100.0
	if AudioServer.get_bus_index("SFX") != -1:
		p.bus = "SFX"
	add_child(p)
	return p


func _physics_process(delta: float) -> void:
	if congelado:
		return
	if estado == Estado.MUERTO:
		return
	tiempo += delta
	enfriamiento_contacto = maxf(enfriamiento_contacto - delta, 0.0)
	if not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador") as Jugador

	match estado:
		Estado.PATRULLA: _patrullar(delta)
		Estado.ACOSO: _acosar(delta)
		Estado.PULSO: _cargar_pulso(delta)
		Estado.RETIRADA: _retirarse(delta)
		Estado.GOLPEADO: _estar_golpeado(delta)

	_actualizar_onda(delta)
	_revisar_contacto()
	move_and_slide()
	_animar_visual()


# ---------------- Estados ----------------
func _patrullar(delta: float) -> void:
	var objetivo := punto_base + Vector2(
		cos(tiempo * 0.7 + fase) * radio_patrulla.x,
		sin(tiempo * 1.3 + fase) * radio_patrulla.y)
	_volar_hacia(objetivo, velocidad_patrulla, delta)
	if _ve_al_jugador():
		_cambiar_estado(Estado.ACOSO)


func _acosar(delta: float) -> void:
	if jugador == null or not _jugador_vivo() or _distancia_jugador() > radio_soltar:
		_cambiar_estado(Estado.PATRULLA)
		return
	angulo_orbita += delta * 1.6
	var desplazamiento := Vector2(cos(angulo_orbita), sin(angulo_orbita) * 0.6 - 0.7) * distancia_acoso
	_volar_hacia(jugador.global_position + desplazamiento, velocidad_acoso, delta)
	temporizador_pulso -= delta
	if temporizador_pulso <= 0.0 and _distancia_jugador() < radio_pulso * 1.3 and onda_t < 0.0:
		_cambiar_estado(Estado.PULSO)


func _cargar_pulso(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	temporizador_estado -= delta
	if temporizador_estado <= 0.0:
		_emitir_pulso()
		temporizador_pulso = intervalo_pulso
		_cambiar_estado(Estado.ACOSO)


func _retirarse(delta: float) -> void:
	temporizador_estado -= delta
	if jugador != null:
		var lejos := (global_position - jugador.global_position).normalized() + Vector2(0, -0.6)
		velocity = velocity.lerp(lejos.normalized() * velocidad_acoso * 1.2, aceleracion * delta)
	if temporizador_estado <= 0.0:
		_cambiar_estado(Estado.ACOSO)


func _estar_golpeado(delta: float) -> void:
	temporizador_estado -= delta
	velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	if temporizador_estado <= 0.0:
		_cambiar_estado(Estado.ACOSO if _ve_al_jugador() else Estado.PATRULLA)


func _cambiar_estado(nuevo: Estado) -> void:
	estado = nuevo
	match nuevo:
		Estado.PULSO:
			temporizador_estado = tiempo_carga
			sprite.play("pulso")
		Estado.RETIRADA:
			temporizador_estado = tiempo_retirada
			sprite.play("vuelo")
		Estado.GOLPEADO:
			temporizador_estado = 0.35
			sprite.play("golpeado")
		Estado.ACOSO, Estado.PATRULLA:
			sprite.play("vuelo")


# ---------------- Movimiento ----------------
func _volar_hacia(objetivo: Vector2, rapidez: float, delta: float) -> void:
	var deseada := (objetivo - global_position) * 2.5
	if deseada.length() > rapidez:
		deseada = deseada.normalized() * rapidez
	deseada += Vector2(sin(tiempo * 9.0 + fase), cos(tiempo * 11.0 + fase * 2.0)) * rapidez * 0.35
	velocity = velocity.lerp(deseada, clampf(aceleracion * delta, 0.0, 1.0))


func _ve_al_jugador() -> bool:
	return jugador != null and _jugador_vivo() and _distancia_jugador() < radio_deteccion


func _jugador_vivo() -> bool:
	return not jugador.muerto


func _distancia_jugador() -> float:
	return global_position.distance_to(jugador.global_position + Vector2(0, 30))


# ---------------- Pulso de sonido ----------------
func _emitir_pulso() -> void:
	onda_t = 0.0
	onda_ya_golpeo = false
	if sonido_pulso.stream != null:
		sonido_pulso.pitch_scale = randf_range(0.95, 1.08)
		sonido_pulso.play()


func _actualizar_onda(delta: float) -> void:
	if onda_t < 0.0:
		return
	onda_t += delta
	var radio_actual := radio_pulso * (onda_t / duracion_onda)
	if not onda_ya_golpeo and jugador != null and _jugador_vivo():
		if absf(_distancia_jugador() - radio_actual) < 45.0:
			onda_ya_golpeo = true
			jugador.alterar_hud(duracion_hud_pulso, 0.6)
	if onda_t >= duracion_onda:
		onda_t = -1.0
	queue_redraw()


func _draw() -> void:
	if onda_t < 0.0:
		return
	var p := onda_t / duracion_onda
	var radio := radio_pulso * p
	var alfa := 1.0 - p
	for i in 3:
		var r := radio - i * 22.0
		if r > 8.0:
			var c := COLOR_HALO if i != 1 else COLOR_NUCLEO
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(c, alfa * (1.0 - i * 0.28)), 5.0 - i, true)


# ---------------- Contacto con el jugador ----------------
func _revisar_contacto() -> void:
	if enfriamiento_contacto > 0.0 or estado == Estado.RETIRADA or estado == Estado.GOLPEADO:
		return
	for cuerpo in zona_contacto.get_overlapping_bodies():
		if cuerpo is Jugador:
			_tocar_jugador(cuerpo)
			return


func _tocar_jugador(j: Jugador) -> void:
	if not j.aturdir(duracion_aturdimiento):
		return
	enfriamiento_contacto = 1.5
	j.alterar_hud(duracion_hud_contacto, 1.0)
	if dano > 0:
		j.recibir_dano(dano, global_position.x)
	if sonido_contacto.stream != null:
		sonido_contacto.play()
	onda_t = -1.0
	queue_redraw()
	_cambiar_estado(Estado.RETIRADA)


# ---------------- Daño recibido ----------------
func recibir_golpe(dir: Vector2, dano: int = 1) -> void:
	if estado == Estado.MUERTO:
		return
	vida._recibir_dano(dano)
	onda_t = -1.0
	queue_redraw()
	if vida.muerte:
		_morir()
		return
	velocity = Vector2(dir.x * retroceso_golpe, -150.0)
	_cambiar_estado(Estado.GOLPEADO)


func _morir() -> void:
	estado = Estado.MUERTO
	remove_from_group("golpeable")
	hitbox.set_deferred("disabled", true)
	zona_contacto.set_deferred("monitoring", false)
	velocity = Vector2.ZERO
	sprite.play("muerte")
	var t := create_tween()
	t.tween_property(glow, "modulate:a", 0.0, 0.4)


# ---------------- Visual ----------------
func _animar_visual() -> void:
	if estado == Estado.MUERTO:
		return
	if absf(velocity.x) > 15.0:
		sprite.flip_h = velocity.x < 0.0
	var base := 1.0 + 0.12 * sin(tiempo * 6.0)
	if estado == Estado.PULSO:
		base = 1.5 + 0.3 * sin(tiempo * 40.0)
		sprite.position = Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
	else:
		sprite.position = Vector2.ZERO
	glow.scale = Vector2(2.4, 2.4) * base
	glow.modulate.a = 0.8 if estado != Estado.GOLPEADO else 1.0


func _al_terminar_animacion() -> void:
	match sprite.animation:
		&"muerte":
			queue_free()
		&"golpeado":
			if estado == Estado.GOLPEADO:
				sprite.play("vuelo")
