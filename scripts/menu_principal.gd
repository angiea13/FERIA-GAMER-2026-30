extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.


func _on_inicio_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_1.tscn")


func _on_configuracion_pressed() -> void:
	pass


func _on_salir_pressed() -> void:
	get_tree().quit()
