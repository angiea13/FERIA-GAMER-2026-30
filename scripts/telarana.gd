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
const SALIDA_HILO:=Vector2(0,-32)

func _ready():
	# Si yo apunto a "siguiente", entonces yo soy su "anterior"
	if siguiente:
		siguiente.anterior = self
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	if not Engine.is_editor_hint():
		add_to_group("telaranas")

func puntos_hilo() -> PackedVector2Array:
	var puntos=PackedVector2Array()
	if siguiente==null:
		return puntos
	var inicio:=SALIDA_HILO
	var fin:= to_local(siguiente.global_position)+SALIDA_HILO
	for i in range(21):
		var t:=i/20.0
		var p:=inicio.lerp(fin,t)
		p.y	+=sin(t*PI)*40
		puntos.append(p)
	return puntos
func _al_entrar(cuerpo):
	if cuerpo is Jugador:
		cuerpo.telarana_actual = self
func _al_salir(cuerpo):
	if cuerpo is Jugador:
		if cuerpo.telarana_actual==self:
			cuerpo.telarana_actual=null
		


func _process(_delta):
	# En el editor, redibujar mientras mueves las telarañas
	if Engine.is_editor_hint():
		queue_redraw()


# --- Parte visual ---
func _draw():
	var pts := puntos_hilo()
	if pts.size() > 1:
		draw_polyline(pts, Color(1, 1, 1, 0.8), 2)
func toca_hilo(punto_global: Vector2, radio: float) -> bool:
	var p := to_local(punto_global)
	var pts := puntos_hilo()
	for i in range(pts.size() - 1):
		var cercano := Geometry2D.get_closest_point_to_segment(p, pts[i], pts[i + 1])
		if p.distance_to(cercano) <= radio:
			return true
	return false
func cortar():
	if siguiente:
		siguiente.anterior = null
	siguiente = null 
	
