extends Area2D

@export var velocidad_impulso: float = 750.0
const TIEMPO_REAPARECER = 2.0

var explotando := false

@onready var salida: Marker2D = $Salida
@onready var sprite: AnimatedSprite2D = $Burbuja

func _ready() -> void:
	sprite.play("Idle")
	body_entered.connect(_al_entrar)
func _al_entrar(cuerpo: Node2D) -> void:

	if cuerpo is Jugador and not explotando:

		var direccion = (salida.global_position - global_position).normalized()

		cuerpo.en_impulso = true
		if velocidad_impulso==0 or velocidad_impulso==10:
			cuerpo.tiempo_impulso=0
		else:
			cuerpo.tiempo_impulso = 0.5
		if velocidad_impulso==10 and cuerpo.dash.activo:
			cuerpo.velocity = direccion*cuerpo.velocity.length() * 1.2
		else:
			cuerpo.velocity = direccion * velocidad_impulso

		explotar()
func explotar() -> void:
	if explotando:
		return

	explotando = true
	$CollisionShape2D.set_deferred("disabled", true)

	sprite.play("explotar")
	await sprite.animation_finished

	visible = false

	await get_tree().create_timer(TIEMPO_REAPARECER).timeout

	visible = true
	sprite.play("Idle")

	$CollisionShape2D.set_deferred("disabled", false)
	explotando = false
