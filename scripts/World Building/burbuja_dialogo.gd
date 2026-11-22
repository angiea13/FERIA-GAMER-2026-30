extends Node2D

signal line_finished

@onready var rich_label = $TextureRect/MarginContainer/RichTextLabel

var full_text = ""
var char_index = 0
var typing_speed = 0.03
var is_typing = false

func show_dialog(text: String):
	full_text = text
	rich_label.text = text
	rich_label.visible_characters = 0
	char_index = 0
	is_typing = true
	_type_next_character()

func _type_next_character():
	if not is_typing:
		return
	if char_index <= full_text.length():
		rich_label.visible_characters = char_index
		char_index += 1
		await get_tree().create_timer(typing_speed).timeout
		_type_next_character()
	else:
		is_typing = false

func advance():
	if is_typing:
		is_typing = false
		char_index = full_text.length()
		rich_label.visible_characters = char_index
	else:
		line_finished.emit()
