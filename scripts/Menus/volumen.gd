extends Node2D


func _on_regresar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Menus/menu_principal.tscn")


func _on_h_slider_value_changed(value: float) -> void:
	
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"),linear_to_db(value))
	


func _on_h_slider_2_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("EFECTOS"),linear_to_db(value))
