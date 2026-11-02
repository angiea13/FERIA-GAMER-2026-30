extends Area2D

@export var velocidad_impulso: float = 900.0
const TIEMPO_REAPARECER = 2.0
var explotando=false

@onready var salida: Marker2D = $Salida
@onready var sprite:AnimatedSprite2D=$Burbuja

func _ready() -> void:
	sprite.play("Idle")
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)

func explotar():
	if explotando:
		return
	explotando = true
	sprite.play("explotar")
	$CollisionShape2D.set_deferred("disabled", true)
	await sprite.animation_finished
	visible = false
	#Cuando ya no                     
	explotando = false
	await get_tree().create_timer(TIEMPO_REAPARECER).timeout
	sprite.play("idle")                                 # su animación normal
	visible = true
	$CollisionShape2D.set_deferred("disabled", false)
	explotando = false
			
func _al_entrar(cuerpo: Node2D) -> void:
	if cuerpo is Jugador and sprite.animation=="Idle":
		var direccion = (salida.global_position - global_position).normalized()
		cuerpo.en_impulso = true
		cuerpo.tiempo_impulso=0.5
		cuerpo.velocity = direccion * velocidad_impulso
		sprite.play("explotar")
		explotando=true

func _al_salir(cuerpo: Node2D) -> void:
	pass
