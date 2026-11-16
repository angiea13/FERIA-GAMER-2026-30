@tool
class_name OrbeVida
extends Area2D
# Orbe de esencia: cura al jugador al tocarlo.
# Si el jugador ya tiene la vida llena el orbe NO se gasta (se queda esperando).
# Se reinicia solo cuando se reinicia el nivel (al morir).

@export var cura := 25
@export var color := Color(0.85, 0.75, 1.0):
	set(valor):
		color = valor
		queue_redraw()

var _usado := false
var _t := 0.0


func _ready() -> void:
	if not Engine.is_editor_hint():
		body_entered.connect(_al_entrar)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _al_entrar(cuerpo: Node2D) -> void:
	if _usado or not (cuerpo is Jugador):
		return
	if not cuerpo.curar(cura):
		return   # ya tenía la vida llena
	_usado = true
	set_deferred("monitoring", false)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2(2.2, 2.2), 0.35)
	tw.tween_property(self, "modulate:a", 0.0, 0.35)
	tw.chain().tween_callback(queue_free)


func _draw() -> void:
	# Orbe flotante: halo + cuerpo + brillo + una chispa que orbita (sin arte externo).
	var flota := sin(_t * 2.2) * 6.0
	var c := Vector2(0.0, flota)
	var pulso := 0.5 + 0.5 * sin(_t * 3.0)
	draw_circle(c, 44.0 + pulso * 6.0, Color(color, 0.10))
	draw_circle(c, 30.0 + pulso * 3.0, Color(color, 0.22))
	draw_circle(c, 17.0, Color(color, 0.95))
	draw_circle(c, 9.0, Color(1.0, 1.0, 1.0, 0.95))
	draw_circle(c + Vector2(-5.0, -6.0), 3.0, Color(1.0, 1.0, 1.0))
	var a := _t * 2.5
	draw_circle(c + Vector2(cos(a), sin(a)) * 28.0, 3.0, Color(1.0, 1.0, 1.0, 0.9))