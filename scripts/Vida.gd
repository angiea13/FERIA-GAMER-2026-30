class_name Vida
extends Node
var vida_max:int
var vida:int
var muerte=false
# Called when the node enters the scene tree for the first time.
func _init(vida_total:int):
	vida_max=vida_total
	vida=vida_max
func _recibir_dano(dano:int):
	vida-=dano
	if vida<=0:
		vida=0
		muerte=true
func _curarse(cura:int):
	vida+=cura
	if vida>=vida_max:
		vida=vida_max
