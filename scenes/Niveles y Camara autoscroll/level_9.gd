extends Node2D

func _ready() -> void:
	TransicionNivel.mostrar("— Nivel 9 - LA RED —")
	$Arana_2.murio.connect(_on_arana_2_murio)
	$Arana_2.fin_dialogo.connect(_on_arana_2_fin_dialogo)

func _on_arana_2_murio() -> void:
	get_tree().change_scene_to_file("res://scenes/Niveles y Camara autoscroll/meh_ending.tscn")

func _on_arana_2_fin_dialogo() -> void:
	_activar_telarana16()

func _activar_telarana16() -> void:
	$Telarana16.siguiente = $Telarana15
	$Telarana16.queue_redraw()  # si el hilo se dibuja con _draw()
