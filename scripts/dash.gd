class_name Dash
extends Node

@export var velocidad := 1200.0
@export var duracion := 0.15
@export var enfriamiento := 0.5

var activo := false
var disponible := true
var direccion := 1.0


func intentar(dir: float) -> void:
	if not disponible:
		return
	direccion = dir
	_ejecutar()


func _ejecutar() -> void:
	activo = true
	disponible = false

	await get_tree().create_timer(duracion).timeout
	activo = false

	await get_tree().create_timer(enfriamiento).timeout
	disponible = true
