extends CharacterBody2D

@export var lines: Array[String] = [""]

@export_group("Glitch")
@export var glitchy: bool = false:
	set(value):
		glitchy = value
		if is_node_ready():
			_reiniciar_glitch()
@export var glitch_duration: float = 20.0   # segundos de diálogo hasta el máximo
@export_range(0.0, 1.0) var glitch_max: float = 1.0
@export var fade_duration: float = 3.0      # segundos que tarda en desaparecer al terminar
@export_group("")

@export_group("Arana_2")
@export var arana_2_path: NodePath
@export_group("")

@onready var dialog_bubble = $BurbujaDialogo
@onready var sprite = $AnimatedSprite2D
@onready var jugador = get_tree().get_first_node_in_group("jugador")
@onready var arana_2: Enemigo2 = get_node_or_null(arana_2_path)

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var current_line = 0
var dialog_active = false
var ya_hablo = false
var player_ref = null

var glitch_time := 0.0
var glitch_mat: ShaderMaterial

func _ready():
	dialog_bubble.visible = false
	dialog_bubble.line_finished.connect(_on_line_finished)
	
	if sprite.material is ShaderMaterial:
		# duplicate() para que cada Rarana tenga su propia intensidad
		glitch_mat = sprite.material.duplicate()
		sprite.material = glitch_mat
	else:
		push_warning("Rarana: el AnimatedSprite2D no tiene un ShaderMaterial para el glitch.")
	_reiniciar_glitch()

func _physics_process(delta):
	# Gravedad
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
	
	move_and_slide()
	
	if jugador:
		sprite.flip_h = jugador.global_position.x > global_position.x

func _process(delta):
	# Solo se distorsiona mientras hay diálogo activo
	if not glitchy or not dialog_active or glitch_mat == null:
		return
	glitch_time += delta
	var t := clampf(glitch_time / glitch_duration, 0.0, 1.0)
	glitch_mat.set_shader_parameter("intensity", t * t * glitch_max)

func _reiniciar_glitch():
	glitch_time = 0.0
	if glitch_mat:
		glitch_mat.set_shader_parameter("intensity", 0.0)

func _input(event):
	if dialog_active and event.is_action_pressed("interact"):
		dialog_bubble.advance()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if dialog_active or ya_hablo:
		return
	if body.is_in_group("jugador"):
		player_ref = body
		player_ref.in_dialog = true
		_start_dialog()

func _start_dialog():
	dialog_active = true
	ya_hablo = true
	current_line = 0
	_reiniciar_glitch()
	dialog_bubble.visible = true
	dialog_bubble.show_dialog(lines[current_line])
	get_tree().call_group("enemigos", "set", "congelado", true)

func _on_line_finished():
	current_line += 1
	if current_line < lines.size():
		dialog_bubble.show_dialog(lines[current_line])
	else:
		_end_dialog()

func _end_dialog():
	dialog_active = false
	dialog_bubble.visible = false
	if player_ref:
		player_ref.in_dialog = false
	get_tree().call_group("enemigos", "set", "congelado", false)
	
	if glitchy:
		_desvanecer()      # se queda con la distorsión que tenía y se desvanece
	else:
		_reiniciar_glitch()

func _desvanecer():
	if arana_2:
		arana_2.activar()
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(queue_free)
