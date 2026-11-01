extends CharacterBody2D


var velocidad: int = 100
var vida = Vida.new(5)
var direccion = 1
var perseguir:bool=false
var atacando:bool=false
var en_recuperacion:bool=false
var dano: int=1
var golpeado:bool=false


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var jugador = get_tree().get_first_node_in_group("jugador")
func _ready() -> void:
	velocity.x = velocidad * direccion
	sprite.animation_finished.connect(_al_terminar_animacion)
func puede_atacar():
	if abs(jugador.position.x-position.x)<150:
	   
		if direccion==1 and position.x>jugador.position.x:
			cambiar_direccion()
		elif direccion==-1 and position.x<jugador.position.x:
			cambiar_direccion()
		return true
	else:
		return false
func _physics_process(delta: float) -> void:
	puede_atacar()
	
	if golpeado:
		sprite.play("Golpeado")
	elif atacando:
		sprite.play("Ataque")
	else:
		sprite.play("Movimiento")
	
	if direccion == 1 and !$Derecha.is_colliding():
		cambiar_direccion()
	elif direccion == -1 and !$Izquierda.is_colliding():
		cambiar_direccion()
	if atacando:
		velocity.x=0
	else:
		velocity.x = velocidad * direccion
	_al_terminar_animacion()
	move_and_slide()

func cambiar_direccion() -> void:
	direccion *= -1
	sprite.flip_h = not sprite.flip_h
func iniciar_ataque():
	if atacando or en_recuperacion:
		return
	velocity.x=0
	sprite.play()
func _al_terminar_animacion():
	if sprite.animation=="Ataque":
		atacando=false
		en_recuperacion=true
		await get_tree().create_timer(1).timeout
		en_recuperacion=false
