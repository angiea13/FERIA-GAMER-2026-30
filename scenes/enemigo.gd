extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var velocidad: int = 100
var vida = Vida.new(5)
var direccion = 1
var perseguir:bool=false
func _ready() -> void:
    velocity.x = velocidad * direccion

func _physics_process(delta: float) -> void:
    sprite.play('Ataque')
    if direccion == 1 and !$Derecha.is_colliding():
        cambiar_direccion()
    elif direccion == -1 and !$Izquierda.is_colliding():
        cambiar_direccion()

    velocity.x = velocidad * direccion
    move_and_slide()

func cambiar_direccion() -> void:
    direccion *= -1
    sprite.flip_h = not sprite.flip_h
        
        
