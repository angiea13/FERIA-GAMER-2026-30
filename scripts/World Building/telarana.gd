@tool                     # para que el dibujo se vea también en el editor
class_name Telarana
extends Area2D

const SALIDA_HILO := Vector2(0, -32)

@export var siguiente: Telarana:
	set(valor):
		siguiente = valor
		queue_redraw()    # redibuja el hilo si cambias el enlace
@export var sustitutos: Array[Telarana] = []:
	set(valor):
		sustitutos = valor
		queue_redraw()
@export var trampas: Array[Node] = []          # arañas que pueden esconderse aquí
@export var radio_activacion := 250.0          # si el jugador se acerca a esta distancia, se meten

var anterior: Telarana = null                  # se calcula solo
var dentro: Array[Node] = []                   # arañas escondidas ahora mismo
var jugador: Node2D


func _ready():
	if siguiente:
		siguiente.anterior = self
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	if not Engine.is_editor_hint():
		add_to_group("telaranas")


func _process(_delta):
	if Engine.is_editor_hint():
		queue_redraw()                         # en el editor, redibuja mientras mueves
		return
	_revisar_trampas()


func _revisar_trampas() -> void:
	if not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador") as Node2D
		if jugador == null:
			return
	if global_position.distance_to(jugador.global_position) > radio_activacion:
		return
	# El jugador está cerca: las arañas trampa se meten en la telaraña
	for enemigo in trampas:
		if is_instance_valid(enemigo) and enemigo.has_method("entrar_en_telarana") \
				and not enemigo.muerto and not enemigo.dentro_telarana:
			enemigo.entrar_en_telarana(self)


func _al_entrar(cuerpo):
	if cuerpo is Jugador:
		cuerpo.telarana_actual = self


func _al_salir(cuerpo):
	if cuerpo is Jugador and cuerpo.telarana_actual == self:
		cuerpo.telarana_actual = null


# ---------------------------------------------------------------- hilos
func puntos_hilo() -> PackedVector2Array:
	var puntos := PackedVector2Array()
	if siguiente == null:
		return puntos
	var inicio := SALIDA_HILO
	var fin := to_local(siguiente.global_position) + SALIDA_HILO
	for i in range(21):
		var t := i / 20.0
		var p := inicio.lerp(fin, t)
		p.y += sin(t * PI) * 40
		puntos.append(p)
	return puntos


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
	# Las arañas que estaban dentro (o entrando) mueren
	for enemigo in dentro.duplicate():
		if is_instance_valid(enemigo):
			enemigo.morir_por_telarana()
	dentro.clear()
	trampas.clear()                            # ya no se puede volver a usar como escondite

	if siguiente:
		siguiente.anterior = null
	if not sustitutos.is_empty():
		siguiente = sustitutos.pop_front()
		siguiente.anterior = self
	else:
		siguiente = null
	
