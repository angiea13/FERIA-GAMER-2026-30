class_name AraniaViral
extends CharacterBody2D

signal murio(arania: AraniaViral)

const FRAMES := 4
const ALTO_FRAME := 16
const SALTO := -430.0

var velocidad := 120.0
var dano := 6
var factor_velocidad := 1.0       # lo sube el enjambre cuando crece
var radio_persecucion := 900.0
var muerta := false

var jugador: Jugador
var escala := 3.0
var sprite: Sprite2D
var zona_dano: Area2D
var direccion := -1               # el dibujo mira a la izquierda
var variacion := randf_range(0.8, 1.2)   # cada araña corre un poco distinto
var tiempo_anim := randf() * 10.0
var enfriamiento_salto := 0.0
var enfriamiento_dano := 0.0


func configurar(material_compartido: Material, textura: Texture2D, escala_sprite: float) -> void:
	escala = escala_sprite
	# Capa 2: la que detecta la espada del jugador (Slash_Area, mask = 2).
	# Máscara 2: choca con el mundo (el tileset está en las capas 1 y 2)
	# pero NO con el jugador, que está en la capa 1.
	collision_layer = 2
	collision_mask = 2
	add_to_group("golpeable")
	add_to_group("enemigos")

	sprite = Sprite2D.new()
	sprite.texture = textura
	sprite.hframes = FRAMES
	sprite.material = material_compartido      # un solo material para todo el enjambre
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(escala, escala)
	sprite.position = Vector2(0.0, -ALTO_FRAME * escala * 0.5)   # los pies quedan en el origen
	add_child(sprite)

	var cuerpo := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = 15.0
	cuerpo.shape = circulo
	cuerpo.position = Vector2(0.0, -17.0)
	add_child(cuerpo)

	zona_dano = Area2D.new()
	zona_dano.collision_layer = 0
	zona_dano.collision_mask = 1          # detecta al jugador
	var forma := CollisionShape2D.new()
	var circulo_dano := CircleShape2D.new()
	circulo_dano.radius = 26.0
	forma.shape = circulo_dano
	forma.position = Vector2(0.0, -20.0)
	zona_dano.add_child(forma)
	add_child(zona_dano)


func nacer() -> void:
	# Efecto de "brota de otra araña"
	sprite.scale = Vector2(0.3, 0.3) * escala
	var t := create_tween()
	t.tween_property(sprite, "scale", Vector2(escala, escala), 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _physics_process(delta: float) -> void:
	if muerta:
		velocity += get_gravity() * delta
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		move_and_slide()
		return

	if not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador") as Jugador
	if not is_on_floor():
		velocity += get_gravity() * delta
	enfriamiento_salto = maxf(enfriamiento_salto - delta, 0.0)
	enfriamiento_dano = maxf(enfriamiento_dano - delta, 0.0)

	var camina := false
	if jugador != null:
		var d := jugador.global_position - global_position
		if global_position.y > jugador.global_position.y + 2000.0:
			_morir(Vector2.ZERO)        # se cayó del mapa
			return
		if d.length() < radio_persecucion:
			if absf(d.x) > 14.0:
				direccion = 1 if d.x > 0.0 else -1
				velocity.x = direccion * velocidad * variacion * factor_velocidad
				camina = true
			else:
				velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			# Salta si choca con una pared o si el jugador está más arriba
			if is_on_floor() and enfriamiento_salto <= 0.0 and (is_on_wall() or d.y < -90.0):
				velocity.y = SALTO
				enfriamiento_salto = randf_range(0.6, 1.4)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)

	_animar(delta, camina)
	move_and_slide()
	_revisar_contacto()


func _animar(delta: float, camina: bool) -> void:
	tiempo_anim += delta * (11.0 if camina else 2.5)
	sprite.frame = int(tiempo_anim) % FRAMES
	sprite.flip_h = direccion > 0       # el dibujo original mira a la izquierda


func _revisar_contacto() -> void:
	if enfriamiento_dano > 0.0:
		return
	for cuerpo in zona_dano.get_overlapping_bodies():
		if cuerpo is Jugador:
			cuerpo.recibir_dano(dano, global_position.x)
			enfriamiento_dano = 0.8
			return


# Lo llama el jugador (player.gd -> golpear()) cuando la espada la toca.
func recibir_golpe(dir: Vector2, _dano: int) -> void:
	_morir(dir)


# Lo usa el enjambre cuando se disipa (el jugador dejó de estar atascado).
func disolver() -> void:
	_morir(Vector2.ZERO)


func _morir(dir: Vector2) -> void:
	if muerta:
		return
	muerta = true
	remove_from_group("golpeable")
	remove_from_group("enemigos")
	collision_layer = 0
	zona_dano.set_deferred("monitoring", false)
	velocity = Vector2(dir.x * 260.0, -240.0)
	murio.emit(self)
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.35)
	t.tween_callback(queue_free)
