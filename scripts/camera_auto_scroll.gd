extends Camera2D


@export var velocidad := Vector2(100, 0)  
# ese vector representa la velocidad en píxeles por segundo

func _process(delta):
	position += velocidad * delta
