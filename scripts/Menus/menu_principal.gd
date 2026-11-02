extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Esto es por un error q hay
	print("Viewport: ", get_viewport().get_visible_rect().size)
	print("Ventana: ", DisplayServer.window_get_size())


# Called every frame. 'delta' is the elapsed time since the previous frame.


func _on_inicio_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Niveles y Camara autoscroll/level_4.tscn")


func _on_configuracion_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Menus/Configuraciones.tscn")


func _on_salir_pressed() -> void:
	get_tree().quit()
