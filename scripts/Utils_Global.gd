extends Node
# Se guarda en user:// (res:// es de solo lectura en el juego exportado)
# y se anota en qué escena se guardó para no colocar al jugador en
# coordenadas de otro nivel.
const SAVE_PATH: String = "user://savegame.bin"


func _escena_actual() -> String:
	var escena := get_tree().current_scene
	return escena.scene_file_path if escena else ""


func save_game() -> void:
	var player = get_tree().get_first_node_in_group("jugador")
	if player == null:
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	var data: Dictionary = {
		"escena": _escena_actual(),
		"position.x": player.position.x,
		"position.y": player.position.y
	}
	file.store_line(JSON.stringify(data))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_line())
	var player = get_tree().get_first_node_in_group("jugador")
	if typeof(data) != TYPE_DICTIONARY or player == null:
		return
	if data.get("escena", "") != _escena_actual():
		return
	player.position.x = float(data["position.x"])
	player.position.y = float(data["position.y"])
