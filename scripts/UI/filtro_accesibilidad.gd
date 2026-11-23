extends CanvasLayer

const SAVE_PATH := "user://settings.cfg"

@onready var rect: ColorRect = $ColorRect
@onready var mat: ShaderMaterial = rect.material

var colorblind_mode: int = 0
var high_contrast: bool = false

func _ready() -> void:
	_load()
	_apply()

func set_colorblind_mode(index: int) -> void:
	colorblind_mode = index
	_apply()
	_save()

func set_high_contrast(enabled: bool) -> void:
	high_contrast = enabled
	_apply()
	_save()

func _apply() -> void:
	rect.visible = colorblind_mode != 0 or high_contrast   # sin coste si todo está apagado
	mat.set_shader_parameter("colorblind_mode", colorblind_mode)
	mat.set_shader_parameter("high_contrast", high_contrast)

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("accessibility", "colorblind_mode", colorblind_mode)
	cfg.set_value("accessibility", "high_contrast", high_contrast)
	cfg.save(SAVE_PATH)

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	colorblind_mode = cfg.get_value("accessibility", "colorblind_mode", 0)
	high_contrast = cfg.get_value("accessibility", "high_contrast", false)
