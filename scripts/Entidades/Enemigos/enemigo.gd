class_name Enemigo
extends CharacterBody2D
# Enemigo base (Caballero). Patrulla, se da la vuelta en bordes y paredes,
# ataca cuando el jugador se acerca y recibe golpes de la espada.
# Para hacer variantes: duplica la escena y cambia los @export en el Inspector.

@export var velocidad := 100.0
@export var vida_maxima := 5
@export var dano := 20                      # el jugador tiene 100 de vida
@export var rango_ataque := 130.0           # distancia en X a la que empieza a atacar
@export var frame_golpe := 3                # frame de "Ataque" en el que realmente pega
@export var tiempo_recuperacion := 1.0      # pausa entre ataques
@export var retroceso_golpe := 350.0
@export var empieza_mirando_derecha := true

var vida: Vida
var direccion := 1
var atacando := false
var golpeado := false
var muerto := false
var ya_pego := false
var tiempo_golpeado := 0.0
var tiempo_en_recuperacion := 0.0
var enfriamiento_giro := 0.0
var zona_dano: Area2D
var jugador: Jugador

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: CollisionShape2D = $Hitbox
@onready var ray_derecha: RayCast2D = $Derecha
@onready var ray_izquierda: RayCast2D = $Izquierda


func _ready() -> void:
	vida = Vida.new(vida_maxima)
	add_to_group("golpeable")   # el jugador solo golpea lo que esté en este grupo
	add_to_group("enemigos")
	direccion = 1 if empieza_mirando_derecha else -1
	sprite.flip_h = direccion < 0
	sprite.animation_finished.connect(_al_terminar_animacion)
	_crear_zona_dano()


func _crear_zona_dano() -> void:
	# Area2D que detecta al jugador delante del enemigo (se crea por código
	# para no tener que tocar la escena).
	zona_dano = Area2D.new()
	zona_dano.collision_layer = 0
	zona_dano.collision_mask = 1
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(100, 121)
	forma.shape = rect
	zona_dano.add_child(forma)
	zona_dano.position = Vector2(direccion * 60.0, hitbox.position.y)
	add_child(zona_dano)


func _physics_process(delta: float) -> void:
	if muerto:
		return
	if not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador") as Jugador
	enfriamiento_giro = maxf(enfriamiento_giro - delta, 0.0)
	tiempo_en_recuperacion = maxf(tiempo_en_recuperacion - delta, 0.0)

	if not is_on_floor():
		velocity += get_gravity() * delta

	if golpeado:
		tiempo_golpeado -= delta
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
		if tiempo_golpeado <= 0.0:
			golpeado = false
	else:
		_ia()

	_animar()
	move_and_slide()


func _ia() -> void:
	if atacando:
		velocity.x = 0.0
		_revisar_golpe()
		return
	if jugador != null and _jugador_en_rango():
		_mirar_al_jugador()
		velocity.x = 0.0
		if tiempo_en_recuperacion <= 0.0:
			iniciar_ataque()
		return
	# Patrulla: gira si no hay suelo delante o si choca con una pared
	var rayo := ray_derecha if direccion == 1 else ray_izquierda
	if is_on_floor() and enfriamiento_giro <= 0.0 and (not rayo.is_colliding() or is_on_wall()):
		cambiar_direccion()
	velocity.x = velocidad * direccion


func _jugador_en_rango() -> bool:
	var d := jugador.global_position - global_position
	return absf(d.x) < rango_ataque and absf(d.y) < 150.0


func _mirar_al_jugador() -> void:
	var quiere := 1 if jugador.global_position.x > global_position.x else -1
	if quiere != direccion:
		cambiar_direccion()


func cambiar_direccion() -> void:
	direccion *= -1
	sprite.flip_h = direccion < 0
	zona_dano.position.x = direccion * 60.0
	enfriamiento_giro = 0.3


func iniciar_ataque() -> void:
	if atacando or golpeado or muerto:
		return
	atacando = true
	ya_pego = false
	velocity.x = 0.0
	sprite.play("Ataque")
	sprite.frame = 0


func _revisar_golpe() -> void:
	if ya_pego or sprite.animation != "Ataque" or sprite.frame < frame_golpe:
		return
	for cuerpo in zona_dano.get_overlapping_bodies():
		if cuerpo is Jugador:
			cuerpo.recibir_dano(dano, global_position.x)
			ya_pego = true
			break


func _animar() -> void:
	if golpeado:
		sprite.play("Golpeado")
	elif atacando:
		sprite.play("Ataque")
	else:
		sprite.play("Movimiento")


func _al_terminar_animacion() -> void:
	if sprite.animation == "Ataque" and atacando:
		atacando = false
		tiempo_en_recuperacion = tiempo_recuperacion


# Lo llama el jugador (player.gd -> golpear()) cuando la espada lo toca.
func recibir_golpe(dir: Vector2) -> void:
	if muerto:
		return
	vida._recibir_dano(1)
	atacando = false
	golpeado = true
	tiempo_golpeado = 0.4
	velocity = Vector2(dir.x * retroceso_golpe, -200.0)
	sprite.self_modulate = Color(1.0, 0.35, 0.35)
	create_tween().tween_property(sprite, "self_modulate", Color.WHITE, 0.25)
	if vida.muerte:
		_morir()


func _morir() -> void:
	muerto = true
	remove_from_group("golpeable")
	hitbox.set_deferred("disabled", true)
	zona_dano.set_deferred("monitoring", false)
	velocity = Vector2.ZERO
	var t := create_tween()
	t.tween_property(sprite, "modulate:a", 0.0, 0.5)
	t.tween_callback(queue_free)
