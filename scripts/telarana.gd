@tool                     # para que el dibujo se vea también en el editor
class_name Telarana       
extends Area2D

# "siguiente" se asigna a mano en el Inspector (@export)
@export var siguiente: Telarana:
	set(valor):
		siguiente = valor
		queue_redraw()    # redibuja el hilo si cambias el enlace

# "anterior" NO se asigna a mano: se calcula solo
var anterior: Telarana = null


func _ready():
	# Si yo apunto a "siguiente", entonces yo soy su "anterior"
	if siguiente:
		siguiente.anterior = self

	
	body_entered.connect(_al_entrar)


func _al_entrar(cuerpo):
	if cuerpo is Jugador:
		cuerpo.telarana_actual = self


func _process(_delta):
	# En el editor, redibujar mientras mueves las telarañas
	if Engine.is_editor_hint():
		queue_redraw()


# --- Parte visual ---
func _draw():
	if siguiente == null:
		return                      # la última no dibuja hilo

	var inicio := Vector2(0, -32)                                       # punto de salida en mi telarana
	var fin := to_local(siguiente.global_position) + Vector2(0, -32)    # punto de llegada en el otro

	var hilo := PackedVector2Array()
	for i in range(21):
		var t := i / 20.0              
		var p := inicio.lerp(fin, t)   
		p.y += sin(t * PI) * 40         # lo cuelga hacia abajo en el centro
		hilo.append(p)

	draw_polyline(hilo, Color(1, 1, 1, 0.8), 2)
