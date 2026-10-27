class_name Jugador
extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var arma: Node2D = $Armas
@onready var anim_arma: AnimationPlayer = $Armas/AnimationPlayer
#Atributos del personaje
var vida=100
#Moviento
const SPEED = 500.0
const JUMP_VELOCITY = -600.0
##Telaranas
var telarana_actual: Telarana = null
##Dash
@onready var dash: Dash = $Dash
var direccion_dash=1
##Efectos
#Tiempo actual del duplicador
var Time_Actual_Dupli:float=0
# Tiempo maximo q debe llegar el time_actual_dupli para poder duplicar
var Time_Dupli:float =0.05
#Tiempo de vida del duplicado=
var Time_Life_Dupli:float=0.2

func _ready():
	arma.visible = false  
	anim_arma.animation_finished.connect(_al_terminar_ataque)
func _al_terminar_ataque(_nombre):
	arma.visible = false
func _physics_process(delta: float) -> void:
	#Variable de duplicado
	Time_Actual_Dupli+=delta
	#Va a ser el dash este no va a ser afectado por la gravedad en el momento del dash
	
	if Input.is_action_just_pressed("hacer_dash"):
		var dir := Input.get_axis("move_left", "move_right")
		if dir != 0:
			direccion_dash = sign(dir)
		dash.intentar(direccion_dash)
	if dash.activo:
		velocity = Vector2(dash.direccion * dash.velocidad, 0)
		if Time_Actual_Dupli>=Time_Dupli:
			Time_Actual_Dupli=0
			crear_duplicado()
		move_and_slide()
		return
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
		direccion_dash=sign(direction)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	if Input.is_action_just_pressed("atacar") and not anim_arma.is_playing():
		print("Ataco")
		arma.visible=true
		anim_arma.play("ataque")
	arma.scale.x=direccion_dash

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
func crear_duplicado():
	var duplicado=$AnimatedSprite2D.duplicate(true)
	duplicado.material=$AnimatedSprite2D.material.duplicate(true)
	duplicado.material.set_shader_parameter("opacity",0.3)
	duplicado.material.set_shader_parameter("r",0)
	duplicado.material.set_shader_parameter("g",0)
	duplicado.material.set_shader_parameter("b",0.8)
	duplicado.material.set_shader_parameter("mix_color",0.7)
	duplicado.position.y+=position.y
	get_parent().add_child(duplicado)
	duplicado.global_position = sprite.global_position
	duplicado.global_scale = sprite.global_scale
	duplicado.pause()
	await get_tree().create_timer(Time_Life_Dupli).timeout
	duplicado.queue_free()
