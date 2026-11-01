extends Node2D

func _ready() -> void:
    ##Viendo el bug
    print("=== CONFIGURACIONES ===")
    print("Viewport: ", get_viewport().get_visible_rect().size)
    print("Ventana: ", DisplayServer.window_get_size())
    print("Posición raíz: ", global_position)
    print("Escala raíz: ", scale)

func _on_regresar_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/Menus/menu_principal.tscn")
