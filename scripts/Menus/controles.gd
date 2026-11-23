extends Node2D
## Menú de controles: muestra las teclas de cada acción y permite cambiarlas.
## Haz clic en una tecla y pulsa la nueva (Esc cancela). Los cambios duran
## mientras el juego esté abierto; al cerrarlo vuelven los del proyecto.

# Nombre EXACTO de la acción en el Mapa de Entrada : texto que se muestra
const ACCIONES := {
	"move_left": "Moverse a la izquierda",
	"move_right": "Moverse a la derecha",
	"jump": "Saltar",
	"atacar": "Atacar",
	"Ataque_Telarana": "Ataque telaraña",
	"hacer_dash": "Dash",
	"ir_siguiente": "Teletransporte siguiente",
	"ir_anterior": "Teletransporte anterior",
	"interact": "Interactuar",
	"Pausar": "Pausa",
}
const RANURAS := 2  # 0 = tecla principal, 1 = tecla alternativa
const TAM_FUENTE := 28
const COLOR_BOTON := Color(0.5922095, 0.53921735, 0.90845287, 1)
const COLOR_ESPERANDO := Color(0.95, 0.75, 0.3, 1)

@onready var camara: Camera2D = $Camera2D
@onready var lista: GridContainer = $Panel/VBox/Lista
var velocidad: float = 100

var accion_esperando := ""
var ranura_esperando := -1


func _ready() -> void:
	$Panel/VBox/Restaurar.pressed.connect(_on_restaurar_pressed)
	construir_lista()


func _input(event: InputEvent) -> void:
	if accion_esperando != "":
		_capturar_tecla(event)
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_on_regresar_pressed()
			return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			camara.position.y -= velocidad
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			camara.position.y += velocidad


func _on_regresar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Menus/menu_principal.tscn")


func _on_restaurar_pressed() -> void:
	InputMap.load_from_project_settings()
	accion_esperando = ""
	construir_lista()


#Lista controles

func construir_lista() -> void:
	for hijo in lista.get_children():
		lista.remove_child(hijo)
		hijo.queue_free()

	for titulo in ["Acción", "Principal", "Alternativa"]:
		var cabecera := _crear_label(titulo)
		cabecera.add_theme_color_override("font_color", COLOR_ESPERANDO)
		lista.add_child(cabecera)

	for accion in ACCIONES:
		if not InputMap.has_action(accion):
			push_warning("Controles: la acción '%s' no existe en el Mapa de Entrada" % accion)
			continue
		lista.add_child(_crear_label(ACCIONES[accion]))
		var eventos := InputMap.action_get_events(accion)
		for ranura in RANURAS:
			var boton := Button.new()
			boton.custom_minimum_size = Vector2(260, 52)
			boton.add_theme_font_size_override("font_size", TAM_FUENTE)
			var esperando: bool = accion == accion_esperando and ranura == ranura_esperando
			boton.add_theme_stylebox_override("normal", _estilo(COLOR_ESPERANDO if esperando else COLOR_BOTON))
			if esperando:
				boton.text = "Pulsa una tecla..."
			elif ranura < eventos.size():
				boton.text = nombre_evento(eventos[ranura])
			else:
				boton.text = "—"
			boton.pressed.connect(_empezar_espera.bind(accion, ranura))
			lista.add_child(boton)


func _crear_label(texto: String) -> Label:
	var label := Label.new()
	label.text = texto
	label.add_theme_font_size_override("font_size", TAM_FUENTE)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _estilo(color: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.set_corner_radius_all(6)
	return estilo


#Reasignar

func _empezar_espera(accion: String, ranura: int) -> void:
	accion_esperando = accion
	ranura_esperando = ranura
	construir_lista.call_deferred()


func _capturar_tecla(event: InputEvent) -> void:
	var nuevo: InputEvent = null

	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_terminar_espera()
			return
		var tecla := InputEventKey.new()
		tecla.physical_keycode = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		nuevo = tecla
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			var raton := InputEventMouseButton.new()
			raton.button_index = event.button_index
			nuevo = raton
	elif event is InputEventJoypadButton and event.pressed:
		var mando := InputEventJoypadButton.new()
		mando.button_index = event.button_index
		nuevo = mando

	if nuevo:
		get_viewport().set_input_as_handled()  # que la tecla no active otro botón
		asignar(accion_esperando, ranura_esperando, nuevo)
		_terminar_espera()


func _terminar_espera() -> void:
	accion_esperando = ""
	ranura_esperando = -1
	construir_lista.call_deferred()


## Pone `evento` en la ranura indicada. Si otra acción ya usaba esa tecla,
## se intercambian: la otra acción se queda con la tecla que había aquí.
func asignar(accion: String, ranura: int, evento: InputEvent) -> void:
	var eventos := InputMap.action_get_events(accion)
	var anterior: InputEvent = eventos[ranura] if ranura < eventos.size() else null

	for otra in ACCIONES:
		if otra == accion or not InputMap.has_action(otra):
			continue
		var de_otra := InputMap.action_get_events(otra)
		for i in de_otra.size():
			if _mismo_evento(de_otra[i], evento):
				if anterior:
					de_otra[i] = anterior
				else:
					de_otra.remove_at(i)
				_reemplazar_eventos(otra, de_otra)
				break

	# quitar la tecla si ya estaba en la otra ranura de esta misma acción
	for i in range(eventos.size() - 1, -1, -1):
		if i != ranura and _mismo_evento(eventos[i], evento):
			eventos.remove_at(i)
			if i < ranura:
				ranura -= 1
	if ranura < eventos.size():
		eventos[ranura] = evento
	else:
		eventos.append(evento)
	_reemplazar_eventos(accion, eventos)


func _reemplazar_eventos(accion: String, eventos: Array) -> void:
	InputMap.action_erase_events(accion)
	for e in eventos:
		InputMap.action_add_event(accion, e)


func _mismo_evento(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		return _codigo_tecla(a) == _codigo_tecla(b)
	if a is InputEventMouseButton and b is InputEventMouseButton:
		return a.button_index == b.button_index
	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return a.button_index == b.button_index
	return false


func _codigo_tecla(e: InputEventKey) -> int:
	return e.physical_keycode if e.physical_keycode != 0 else e.keycode


#Texto

static func nombre_evento(e: InputEvent) -> String:
	if e is InputEventKey:
		var codigo: int = e.keycode
		if e.physical_keycode != 0:
			codigo = DisplayServer.keyboard_get_keycode_from_physical(e.physical_keycode)
		match codigo:
			KEY_SPACE: return "Espacio"
			KEY_LEFT: return "Flecha izq."
			KEY_RIGHT: return "Flecha der."
			KEY_UP: return "Flecha arriba"
			KEY_DOWN: return "Flecha abajo"
			KEY_SHIFT: return "Shift"
			KEY_CTRL: return "Ctrl"
			KEY_ENTER: return "Enter"
			KEY_TAB: return "Tab"
		return OS.get_keycode_string(codigo)
	if e is InputEventMouseButton:
		match e.button_index:
			MOUSE_BUTTON_LEFT: return "Clic izquierdo"
			MOUSE_BUTTON_RIGHT: return "Clic derecho"
			MOUSE_BUTTON_MIDDLE: return "Clic central"
		return "Ratón %d" % e.button_index
	if e is InputEventJoypadButton:
		return "Mando botón %d" % e.button_index
	return e.as_text()
