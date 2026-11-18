extends Control

const DESIGN_SIZE := Vector2(1920, 1080)  # tamaño original de la imagen del splash

@onready var logo: TextureRect = $TextureRect

func _ready() -> void:
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_SCALE

	get_viewport().size_changed.connect(_ajustar_logo)
	_ajustar_logo()

	logo.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(logo, "modulate:a", 1.0, 1.5)  # fade-in
	tween.tween_interval(2.0)                           # visible
	tween.tween_property(logo, "modulate:a", 0.0, 1.0)  # fade-out (opcional)
	tween.tween_callback(_ir_al_menu)

func _ajustar_logo() -> void:
	var vp := get_viewport_rect().size
	var escala := vp.x / DESIGN_SIZE.x        # escala según el ANCHO
	logo.size = DESIGN_SIZE * escala
	logo.position = (vp - logo.size) / 2.0    # centrado en ambos ejes

func _ir_al_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/Menus/menu_principal.tscn")
