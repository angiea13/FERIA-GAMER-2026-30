extends Area2D

@export var velocidad_impulso: float = 900.0

@onready var salida: Marker2D = $Salida

func _ready() -> void:
    body_entered.connect(_al_entrar)
    body_exited.connect(_al_salir)


func _al_entrar(cuerpo: Node2D) -> void:
    if cuerpo is Jugador :
        var direccion = (salida.global_position - global_position).normalized()
        cuerpo.en_impulso = true
        cuerpo.tiempo_impulso=0.5
        cuerpo.velocity = direccion * velocidad_impulso


func _al_salir(cuerpo: Node2D) -> void:
    pass
