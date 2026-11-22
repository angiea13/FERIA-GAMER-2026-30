extends Node2D

signal line_finished

@onready var rich_label = $NinePatchRect/MarginContainer/RichTextLabel
@onready var panel = $NinePatchRectl

var full_text = ""
var char_index = 0
var typing_speed = 0.03  # segundos entre cada letra

func set_text(text: String):
	rich_label.text = text

func show_dialog(text: String):
	full_text = text
	rich_label.text = text
	rich_label.visible_characters = 0
	char_index = 0
	_type_next_character()

func _type_next_character():
	if char_index <= full_text.length():
		rich_label.visible_characters = char_index
		char_index += 1
		await get_tree().create_timer(typing_speed).timeout
		_type_next_character()
