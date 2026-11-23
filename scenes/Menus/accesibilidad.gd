extends Node2D

@onready var option_button: OptionButton = $ButtonManager/OptionButton
@onready var check_contraste: CheckBox = $ButtonManager/AltoContraste

func _ready() -> void:
	option_button.select(FiltroAccesibilidad.colorblind_mode)
	check_contraste.set_pressed_no_signal(FiltroAccesibilidad.high_contrast)

func _on_option_button_item_selected(index: int) -> void:
	FiltroAccesibilidad.set_colorblind_mode(index)

func _on_alto_contraste_toggled(toggled_on: bool) -> void:
	FiltroAccesibilidad.set_high_contrast(toggled_on)
	
func _on_regresar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Menus/menu_principal.tscn")
