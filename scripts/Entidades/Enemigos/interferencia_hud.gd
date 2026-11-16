class_name InterferenciaHUD
extends CanvasLayer


const COLOR_HALO := Color("#FFD66B")
const COLOR_INSIGNIA := Color("#E5484D")

var tiempo_restante := 0.0
var duracion_total := 1.0
var intensidad := 1.0
var cuenta_spawn := 0.0
var tinte: ColorRect
var originales := {}


static func activar(arbol: SceneTree, duracion: float, fuerza: float = 1.0) -> void:
	var escena := arbol.current_scene
	if escena == null:
		return
	var existente := arbol.get_first_node_in_group("interferencia_hud") as InterferenciaHUD
	if existente == null:
		existente = InterferenciaHUD.new()
		existente.add_to_group("interferencia_hud")
		escena.add_child(existente)
	existente._iniciar(duracion, fuerza)


func _ready() -> void:
	layer = 8
	tinte = ColorRect.new()
	tinte.color = Color(COLOR_HALO, 0.0)
	tinte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tinte.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(tinte)
	set_process(false)


func _iniciar(duracion: float, fuerza: float) -> void:
	if tiempo_restante <= 0.0:
		intensidad = fuerza
		tiempo_restante = duracion
		duracion_total = maxf(duracion, 0.1)
	else:
		intensidad = maxf(intensidad, fuerza)
		tiempo_restante = maxf(tiempo_restante, duracion)
		duracion_total = maxf(duracion_total, tiempo_restante)
	set_process(true)


func _process(delta: float) -> void:
	if tiempo_restante <= 0.0:
		return
	tiempo_restante -= delta
	var p := clampf(tiempo_restante / duracion_total, 0.0, 1.0)

	var parpadeo := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.04)
	tinte.color.a = 0.10 * intensidad * p * parpadeo

	cuenta_spawn -= delta
	if cuenta_spawn <= 0.0 and tiempo_restante > 0.25:
		cuenta_spawn = lerpf(0.28, 0.12, intensidad * 0.5)
		_crear_globito()

	for nodo in get_tree().get_nodes_in_group("hud"):
		if nodo is Control:
			if not originales.has(nodo):
				originales[nodo] = nodo.position
			nodo.position = originales[nodo] + Vector2(
				randf_range(-6.0, 6.0), randf_range(-4.0, 4.0)) * intensidad * p

	if tiempo_restante <= 0.0:
		_terminar()


func _terminar() -> void:
	tinte.color.a = 0.0
	for nodo in originales:
		if is_instance_valid(nodo):
			nodo.position = originales[nodo]
	originales.clear()
	intensidad = 1.0
	duracion_total = 1.0
	set_process(false)


func _crear_globito() -> void:
	var tam := get_viewport().get_visible_rect().size
	var g := Globito.new()
	g.numero = randi_range(1, 9)
	g.position = Vector2(randf_range(60.0, tam.x - 60.0), randf_range(60.0, tam.y - 60.0))
	add_child(g)


class Globito extends Control:
	var numero := 1
	var edad := 0.0
	var vida_total := 0.9

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		vida_total = randf_range(0.6, 1.0)

	func _process(delta: float) -> void:
		edad += delta
		queue_redraw()
		if edad >= vida_total:
			queue_free()

	func _draw() -> void:
		var p := edad / vida_total
		var escala := 1.0 + 0.5 * sin(minf(p * 3.0, 1.0) * PI) - p * 0.3
		var alfa := 1.0 - maxf(p - 0.6, 0.0) / 0.4
		var r := 22.0 * escala
		draw_circle(Vector2.ZERO, r + 14.0, Color(Color("#FFD66B"), 0.18 * alfa))
		draw_circle(Vector2.ZERO, r + 3.0, Color(1, 1, 1, 0.9 * alfa))
		draw_circle(Vector2.ZERO, r, Color(Color("#E5484D"), alfa))
		var fuente := ThemeDB.fallback_font
		draw_string(fuente, Vector2(-8.0, 9.0), str(numero), HORIZONTAL_ALIGNMENT_CENTER, 16.0, 28, Color(1, 1, 1, alfa))