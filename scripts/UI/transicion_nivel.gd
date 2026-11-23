extends CanvasLayer

@onready var fondo = $Fondo
@onready var titulo = $Titulo

func mostrar(texto: String, duracion_visible: float = 1.5, duracion_fade: float = 1.0):
	titulo.text = texto
	fondo.modulate.a = 1.0
	titulo.modulate.a = 1.0
	visible = true
	
	await get_tree().create_timer(duracion_visible).timeout
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(fondo, "modulate:a", 0.0, duracion_fade)
	tween.tween_property(titulo, "modulate:a", 0.0, duracion_fade)
	
	await tween.finished
	visible = false
