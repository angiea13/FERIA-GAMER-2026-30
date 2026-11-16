class_name Vida
extends RefCounted


var vida_max: int
var vida: int
var muerte := false


func _init(vida_total: int) -> void:
	vida_max = maxi(vida_total, 1)   # evita vida máxima 0 o negativa
	vida = vida_max



func _recibir_dano(dano: int) -> int:
	if muerte or dano <= 0:
		return 0
	var antes := vida
	vida = maxi(vida - dano, 0)
	if vida == 0:
		muerte = true
	return antes - vida



func _curarse(cura: int) -> int:
	if muerte or cura <= 0:
		return 0
	var antes := vida
	vida = mini(vida + cura, vida_max)
	return vida - antes


func esta_llena() -> bool:
	return vida >= vida_max


func porcentaje() -> float:
	return float(vida) / float(vida_max)


func reiniciar() -> void:
	vida = vida_max
	muerte = false