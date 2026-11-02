extends Node2D

@export var tecla: String = "C"

@onready var texto: Label = $Indicador_Tecla/Label

func _ready():
	texto.text = tecla
