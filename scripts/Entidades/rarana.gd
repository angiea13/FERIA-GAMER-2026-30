extends CharacterBody2D

@export var lines: Array[String] = [""]

@onready var dialog_bubble = $BurbujaDialogo

var current_line = 0
var dialog_active = false
var player_ref = null

func _ready():
	dialog_bubble.visible = false
	dialog_bubble.line_finished.connect(_on_line_finished)

func _input(event):
	if dialog_active and event.is_action_pressed("interact"):
		dialog_bubble.advance()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if dialog_active:
		return  # evita que se reinicie si ya está hablando (y evita el doble-trigger)
	if body.is_in_group("jugador"):
		player_ref = body
		player_ref.in_dialog = true
		_start_dialog()

func _start_dialog():
	dialog_active = true
	current_line = 0
	dialog_bubble.visible = true
	dialog_bubble.show_dialog(lines[current_line])

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
