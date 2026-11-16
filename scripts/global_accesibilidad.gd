extends Node

var alto_contraste_activado: bool = false:
	set(value):
		alto_contraste_activado = value
		aplicar_filtro_global()

var filtro_daltonismo_activado: bool = false:
	set(value):
		filtro_daltonismo_activado = value
		aplicar_filtro_global()

var capa_filtro: CanvasLayer = null

func aplicar_filtro_global() -> void:
	var tree = Engine.get_main_loop() as SceneTree
	if not tree or not tree.root:
		return
		
	if not capa_filtro:
		capa_filtro = CanvasLayer.new()
		capa_filtro.layer = 128
		var color_rect = ColorRect.new()
		color_rect.name = "FiltroRect"
		color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		capa_filtro.add_child(color_rect)
		tree.root.call_deferred("add_child", capa_filtro)

	await tree.process_frame
	if capa_filtro and capa_filtro.has_node("FiltroRect"):
		var rect = capa_filtro.get_node("FiltroRect") as ColorRect
		
		# Evaluamos cada opción por separado o combinadas de forma lógica
		if alto_contraste_activado and filtro_daltonismo_activado:
			# Si ambos están activos: contraste fuerte con matiz de corrección
			rect.color = Color(1.2, 1.2, 1.4, 0.15)
		elif alto_contraste_activado:
			# Solo alto contraste (brillo y claridad en los bordes)
			rect.color = Color(1.3, 1.3, 1.3, 0.15)
		elif filtro_daltonismo_activado:
			# Solo daltonismo (filtro de compensación de color, sin ver pálido)
			rect.color = Color(0.85, 1.05, 1.25, 0.12)
		else:
			# Nada activo, pantalla normal
			rect.color = Color(1, 1, 1, 0)
