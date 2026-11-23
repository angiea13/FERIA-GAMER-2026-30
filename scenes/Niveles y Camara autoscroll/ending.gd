extends Control

@export var imagen_fondo: Texture2D
@export_multiline var texto: String = ""
@export var velocidad_scroll: float = 40.0        # píxeles por segundo
@export var fundido_entrada: float = 1.5
@export var tiempo_extra_final: float = 2.0       # cuánto se queda quieto el texto al terminar de subir
@export var escena_al_terminar: String = ""       # res://... o uid://... a dónde ir después (vacío = no hace nada)
@export var permitir_saltar: bool = true          # pulsar "interact" salta directo al final del scroll

@onready var fondo: TextureRect = $Fondo
@onready var scroll: Control = $Scroll
@onready var texto_label: RichTextLabel = $Scroll/Texto
@onready var negro: ColorRect = $Negro

var _terminado := false


func _ready() -> void:
	fondo.texture = imagen_fondo
	texto_label.text = texto

	negro.color = Color(0, 0, 0, 1)

	await get_tree().process_frame   # deja que el RichTextLabel calcule su altura real
	scroll.position.y = get_viewport_rect().size.y

	var t := create_tween()
	t.tween_property(negro, "color:a", 0.0, fundido_entrada)


func _process(delta: float) -> void:
	if _terminado:
		return
	scroll.position.y -= velocidad_scroll * delta
	if scroll.position.y + texto_label.size.y < 0.0:
		_terminado = true
		set_process(false)
		await get_tree().create_timer(tiempo_extra_final).timeout
		_terminar()


func _input(event: InputEvent) -> void:
	if permitir_saltar and not _terminado and event.is_action_pressed("interact"):
		# salta directo al final del scroll, como si ya hubiera subido todo
		scroll.position.y = -texto_label.size.y - 1.0


func _terminar() -> void:
	if escena_al_terminar != "":
		get_tree().change_scene_to_file(escena_al_terminar)
