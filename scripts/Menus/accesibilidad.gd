extends Node2D

func _ready() -> void:
	# Sincroniza el estado inicial de las opciones con los nombres y ruta exacta de tus nodos
	$"ButtonManager/Alto Contraste".button_pressed = GlobalAccesibilidad.alto_contraste_activado
	$"ButtonManager/Daltonismo".button_pressed = GlobalAccesibilidad.filtro_daltonismo_activado

func _on_regresar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Menus/Configuraciones.tscn")

func _on_alto_contraste_toggled(toggled_on: bool) -> void:
	GlobalAccesibilidad.alto_contraste_activado = toggled_on

func _on_daltonismo_toggled(toggled_on: bool) -> void:
	GlobalAccesibilidad.filtro_daltonismo_activado = toggled_on
