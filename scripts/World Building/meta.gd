@tool
extends Area2D
# Portal de fin de nivel. Elige en el Inspector a qué escena lleva.

@export_file("*.tscn") var siguiente_nivel: String = ""
@export var color := Color(1.0, 0.55, 0.3)

var _usado := false


func _ready() -> void:
	if not Engine.is_editor_hint():
		body_entered.connect(_al_entrar)


func _al_entrar(cuerpo: Node2D) -> void:
	if _usado or not (cuerpo is Jugador):
		return
	if siguiente_nivel.is_empty():
		push_warning("Meta sin 'siguiente_nivel' asignado")
		return
	_usado = true
	get_tree().change_scene_to_file.call_deferred(siguiente_nivel)


func _draw() -> void:
	# Portal placeholder: marco naranja + interior claro (mismos colores que el tileset)
	draw_rect(Rect2(-40, -140, 80, 140), Color(color, 0.25))
	draw_rect(Rect2(-40, -140, 80, 140), color, false, 4.0)
	draw_rect(Rect2(-10, -130, 20, 120), Color(1, 1, 1, 0.55))
