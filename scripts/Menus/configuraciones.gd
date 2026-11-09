extends Node2D


func _on_regresar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Menus/menu_principal.tscn")

func _on_volumen_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Menus/Volumen.tscn")
