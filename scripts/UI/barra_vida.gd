class_name BarraVida
extends CanvasLayer
# Barra de energía del jugador, dibujada por código (no necesita escena).
# La crea player.gd en _ready(), así aparece en TODOS los niveles sin tocarlos.

var jugador = null   # sin tipo a propósito: lo asigna player.gd

var _panel: PanelVida
var _velo: ColorRect
var _texto_muerte: Label


func _ready() -> void:
	layer = 4   # debajo del menú de pausa (layer 5)

	_panel = PanelVida.new()
	_panel.position = Vector2(28, 24)
	add_child(_panel)

	_velo = ColorRect.new()
	add_child(_velo)
	_velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_velo.color = Color(0.03, 0.01, 0.06, 0.0)
	_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_texto_muerte = Label.new()
	add_child(_texto_muerte)
	_texto_muerte.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_texto_muerte.text = "HAS CAÍDO"
	_texto_muerte.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto_muerte.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_texto_muerte.add_theme_font_size_override("font_size", 72)
	_texto_muerte.add_theme_color_override("font_color", Color(0.86, 0.22, 0.34))
	_texto_muerte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texto_muerte.modulate.a = 0.0

	if jugador != null:
		jugador.vida_cambiada.connect(_al_cambiar_vida)
		jugador.curado.connect(_al_curar)
		jugador.murio.connect(_al_morir)
		_panel.fijar(jugador.vida.vida, jugador.vida.vida_max)


func _al_cambiar_vida(actual: int, maxima: int) -> void:
	_panel.maxima = maxima
	_panel.real = actual


func _al_curar(_cantidad: int) -> void:
	_panel.destello = 1.0


func _al_morir() -> void:
	var t := create_tween()
	t.tween_property(_velo, "color:a", 0.88, 0.7)
	t.parallel().tween_property(_texto_muerte, "modulate:a", 1.0, 0.5)


# ------------------------------------------------------------------
class PanelVida extends Control:
	const ANCHO := 440.0
	const ALTO := 30.0
	const PUNTOS_POR_DIVISION := 20.0   # = lo que quita un golpe de caballero

	var maxima := 100.0
	var real := 100.0        # vida de verdad
	var mostrada := 100.0    # barra roja (alcanza a "real" rápido)
	var fantasma := 100.0    # estela clara (alcanza despacio: se ve lo que acabas de perder)
	var destello := 0.0      # 1 → 0 al curarse
	var tiempo := 0.0

	func _init() -> void:
		add_to_group("hud")   # InterferenciaHUD (Notificador) hace vibrar los nodos de este grupo
		custom_minimum_size = Vector2(ANCHO, ALTO + 26.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func fijar(valor: float, maximo: float) -> void:
		maxima = maximo
		real = valor
		mostrada = valor
		fantasma = valor
		queue_redraw()

	func _process(delta: float) -> void:
		tiempo += delta
		mostrada = move_toward(mostrada, real, maxima * 1.5 * delta)
		if fantasma > mostrada:
			fantasma = move_toward(fantasma, mostrada, maxima * 0.25 * delta)
		else:
			fantasma = mostrada
		destello = move_toward(destello, 0.0, delta * 2.0)
		queue_redraw()

	func _draw() -> void:
		var marco := Rect2(0.0, 0.0, ANCHO, ALTO)
		var oscuro := Color(0.06, 0.03, 0.11)
		draw_rect(marco.grow(5.0), Color(oscuro, 0.85))
		draw_rect(marco, Color(0.16, 0.08, 0.2))

		var f := clampf(fantasma / maxima, 0.0, 1.0)
		var m := clampf(mostrada / maxima, 0.0, 1.0)
		draw_rect(Rect2(0.0, 0.0, ANCHO * f, ALTO), Color(0.93, 0.85, 1.0, 0.9))

		var color := Color(0.86, 0.22, 0.34)
		if real / maxima <= 0.3:
			color = color.lerp(Color(1.0, 0.5, 0.55), 0.5 + 0.5 * sin(tiempo * 8.0))
		color = color.lerp(Color(1.0, 0.95, 1.0), destello * 0.7)
		draw_rect(Rect2(0.0, 0.0, ANCHO * m, ALTO), color)
		draw_rect(Rect2(0.0, 0.0, ANCHO * m, ALTO * 0.3), Color(1.0, 1.0, 1.0, 0.18))

		var divisiones := int(maxima / PUNTOS_POR_DIVISION)
		for i in range(1, divisiones):
			var x := ANCHO * float(i) / float(divisiones)
			draw_line(Vector2(x, 0.0), Vector2(x, ALTO), oscuro, 3.0)

		draw_rect(marco, Color(0.596, 0.544, 0.884), false, 3.0)
		var fuente := ThemeDB.fallback_font
		draw_string(fuente, Vector2(2.0, ALTO + 24.0), "ENERGÍA  %d / %d" % [roundi(real), roundi(maxima)],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.93, 0.85, 1.0))