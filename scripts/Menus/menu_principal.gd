extends Node2D

# Called every frame. 'delta' is the elapsed time since the previous frame.


func _on_inicio_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Niveles y Camara autoscroll/level_5.tscn")


func _on_configuracion_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Menus/Configuraciones.tscn")


func _on_salir_pressed() -> void:
	get_tree().quit()
