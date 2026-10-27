class_name Jugador
extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 500.0
const JUMP_VELOCITY = -600.0
var telarana_actual: Telarana = null

func _physics_process(delta: float) -> void:
	# Gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Teletransporte
	if telarana_actual:
		if Input.is_action_just_pressed("ir_siguiente"):
			teletransportar(telarana_actual.siguiente)
		elif Input.is_action_just_pressed("ir_anterior"):
			teletransportar(telarana_actual.anterior)

	# Salto
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Movimiento horizontal
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	_update_animation(direction)


func teletransportar(destino: Telarana) -> void:
	if destino == null:
		return
	global_position = destino.global_position + Vector2(0, -16)
	velocity = Vector2.ZERO
	telarana_actual = destino


func _update_animation(direction: float) -> void:
	if not is_on_floor():
		if velocity.y < 0:
			sprite.play("jump")
		else:
			sprite.play("falling")
	elif direction:
		sprite.play("moving")
	else:
		sprite.play("idle")
