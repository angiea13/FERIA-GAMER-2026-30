extends Node
const SAVE_PATH: String= "res://savegame.bin"
func save_game():
	var file=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	var player = get_tree().get_first_node_in_group("jugador")
	var data: Dictionary={
		"position.x": player.position.x,
		"position.y":player.position.y
	}
	var jstr=JSON.stringify(data)
	file.store_line(jstr)
func load_game():
	var file=FileAccess.open(SAVE_PATH,FileAccess.READ)
	if not file:
		return
	if file==null:
		return
	if FileAccess.file_exists(SAVE_PATH)==true:
		if not file.eof_reached():
			var current_line=JSON.parse_string(file.get_line())
			var player = get_tree().get_first_node_in_group("jugador")
			if current_line:
				player.position.x=int(current_line["position.x"])
				player.position.y=int(current_line["position.y"])
