class_name Dash
extends Node

@export var velocidad := 1200.0
@export var duracion := 0.15
@export var enfriamiento := 0.5
var maximo_dash
var cantidad_de_dash
var activo := false
var disponible := true
var direccion := 1.0
func configurar(maximos:int):
    maximo_dash=maximos
    cantidad_de_dash=maximo_dash
func recuperar():
    cantidad_de_dash=maximo_dash
func menos_dash():
    cantidad_de_dash-=1
    if cantidad_de_dash<=0:
        cantidad_de_dash=0

func intentar(dir: float) -> void:
    if not disponible or cantidad_de_dash==0:
        return
    direccion = dir
    _ejecutar()


func _ejecutar() -> void:
    menos_dash()
    activo = true
    disponible = false

    await get_tree().create_timer(duracion).timeout
    activo = false

    await get_tree().create_timer(enfriamiento).timeout
    disponible = true
