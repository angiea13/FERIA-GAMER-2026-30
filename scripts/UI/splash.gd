extends Control

const DESIGN_SIZE := Vector2(1920, 1080)

@onready var logo: TextureRect = $TextureRect

func _ready() -> void:
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_SCALE

	get_viewport().size_changed.connect(_ajustar_logo)
	_ajustar_logo()
	
	print("Viewport size en _ready: ", get_viewport_rect().size)
	print("Logo size calculado: ", logo.size)
	print("Logo position calculado: ", logo.position)
	print("Logo texture: ", logo.texture)

	logo.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(logo, "modulate:a", 1.0, 1.5)
	tween.tween_interval(2.0)
	tween.tween_property(logo, "modulate:a", 0.0, 1.0)
	tween.tween_callback(_ir_al_menu)

func _ajustar_logo() -> void:
	var vp := get_viewport_rect().size
	var escala := vp.x / DESIGN_SIZE.x
	logo.size = DESIGN_SIZE * escala
	logo.position = (vp - logo.size) / 2.0

func _ir_al_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/Menus/menu_principal.tscn")
