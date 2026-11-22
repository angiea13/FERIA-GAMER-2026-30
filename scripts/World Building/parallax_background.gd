extends ParallaxBackground

const ANCHO_BASE := 1672.0
const ALTO_BASE := 941.0
const ZOOM_EXTRA := 1.12
# cielo, luna, nubes, ruinas lejanas, telarañas, medias lejanas, medias cercanas, primer plano
const VELOCIDADES := [0.10, 0.10, 0.10, 0.10, 0.10, 0.11, 0.12, 0.13]

@export var desplazamiento_y: float = 0.0

func _ready() -> void:
	var vp := get_viewport().get_visible_rect().size
	var s := vp.x / ANCHO_BASE * ZOOM_EXTRA
	var i := 0
	for layer in get_children():
		if layer is ParallaxLayer:
			var spr: Sprite2D = null
			for c in layer.get_children():
				if c is Sprite2D:
					spr = c
			if spr != null and spr.texture != null:
				var tam := spr.texture.get_size()
				var ancho := tam.x * s
				var v: float = VELOCIDADES[i] if i < VELOCIDADES.size() else 0.0
				spr.centered = false
				spr.scale = Vector2(s, s)
				spr.position = Vector2(
					-(ANCHO_BASE * s - vp.x) / 2.0,
					-(ALTO_BASE * s - vp.y) / 2.0 + desplazamiento_y)
				layer.motion_scale = Vector2(v, 0.0)
				if v > 0.0:
					# copia en espejo al lado, para que la repetición no tenga corte
					var espejo := spr.duplicate() as Sprite2D
					espejo.flip_h = true
					espejo.position.x = spr.position.x + ancho
					layer.add_child(espejo)
					layer.motion_mirroring = Vector2(ancho * 2.0, 0.0)
				else:
					layer.motion_mirroring = Vector2.ZERO
				print(layer.name, " v=", v, " mirroring=", layer.motion_mirroring, " tex=", tam)
		i += 1
	await get_tree().process_frame
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		scroll_base_offset = cam.get_screen_center_position() - vp / (2.0 * cam.zoom)
func _process(delta: float) -> void:
	var velocidad=10
	scroll_offset.x-=velocidad*delta
