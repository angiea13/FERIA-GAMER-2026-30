class_name Vida
extends RefCounted
# RefCounted (en vez de Node): es solo un dato, no necesita estar en el árbol
# y se libera solo. Con Node cada Vida.new() quedaba huérfano en memoria.
var vida_max: int
var vida: int
var muerte := false

func _init(vida_total: int) -> void:
	vida_max = vida_total
	vida = vida_max

func _recibir_dano(dano: int) -> void:
	vida -= dano
	if vida <= 0:
		vida = 0
		muerte = true

func _curarse(cura: int) -> void:
	vida += cura
	if vida >= vida_max:
		vida = vida_max
