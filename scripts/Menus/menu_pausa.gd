extends Control

func pause():
	get_tree().paused=!get_tree().paused
	visible=get_tree().paused
	$Sonido.stream_paused = get_tree().paused
func _input(event):
	if event.is_action_pressed("Pausar"):
		pause()

func _on_resume_pressed() -> void:
	pause()


func _on_reinicio_pressed() -> void:
	get_tree().paused=false
	get_tree().reload_current_scene()


func _on_menu_principal_pressed() -> void:
	get_tree().paused=false
	get_tree().change_scene_to_file("res://scenes/Menus/menu_principal.tscn")


func _on_salir_pressed() -> void:
	get_tree().quit()
