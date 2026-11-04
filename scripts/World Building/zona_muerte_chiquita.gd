extends Area2D
# Franja bajo el nivel: si el jugador cae aquí, muere y reaparece.

func _ready() -> void:
	collision_mask = 3
	body_entered.connect(_al_entrar)


func _al_entrar(cuerpo: Node2D) -> void:
	if cuerpo is Jugador:
		cuerpo.matar()
	elif cuerpo is Enemigo:
		cuerpo.queue_free()
