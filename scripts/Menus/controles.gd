extends Node2D
@onready var camara:Camera2D=$Camera2D
var velocidad: float=100

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed:
			camara.position.y-=velocidad
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			camara.position.y+=velocidad



func _on_regresar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Menus/Configuraciones.tscn") # Replace with function body.
