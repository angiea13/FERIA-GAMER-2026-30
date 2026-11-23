extends CharacterBody2D

@export var lines: Array[String] = [""]

@onready var dialog_bubble = $BurbujaDialogo
@onready var sprite = $AnimatedSprite2D
@onready var jugador = get_tree().get_first_node_in_group("jugador")

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var current_line = 0
var dialog_active = false
var ya_hablo = false
var player_ref = null

func _ready():
	dialog_bubble.visible = false
	dialog_bubble.line_finished.connect(_on_line_finished)

func _physics_process(delta):
	# Gravedad
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
	
	move_and_slide()
	
	if jugador:
		sprite.flip_h = jugador.global_position.x > global_position.x

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
