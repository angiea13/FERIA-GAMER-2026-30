extends Area2D

func _ready() -> void:
	body_entered.connect(_al_entrar)

func _al_entrar(body: Node2D) -> void:
	if body is Jugador:
		UtilsGlobal.save_game()
