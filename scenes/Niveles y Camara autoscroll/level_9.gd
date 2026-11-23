extends Node2D

func _ready() -> void:
	TransicionNivel.mostrar("— Nivel 9 - LA RED —")
	$Arana_2.murio.connect(_on_arana_2_murio)

func _on_arana_2_murio() -> void:
	$Telarana16.siguiente = $Telarana15
	$Telarana16.queue_redraw()  # si el hilo se dibuja con _draw()
