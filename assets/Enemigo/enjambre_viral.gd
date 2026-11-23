class_name EnjambreViral
extends Node2D


signal crecio(cantidad: int)

const RUTA_HOJA := "res://assets/Enemigo/enjambre viral hoja.png"

# Shader: detecta las marcas coral del sprite (r alto, g bajo) y las aviva
# según "intensidad". El cuerpo (#1A0F1F) casi no se toca.
const CODIGO_SHADER := """
shader_type canvas_item;

uniform float intensidad = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float marca = clamp((c.r - c.g * 1.6) * 2.2, 0.0, 1.0);
	float pulso = 0.5 + 0.5 * sin(TIME * (3.0 + 7.0 * intensidad));
	float k = intensidad * (0.3 + 0.5 * pulso);
	vec3 viva = mix(vec3(0.878, 0.271, 0.482), vec3(1.0, 0.55, 0.65), k) * (0.75 + 0.25 * intensidad);
	COLOR = vec4(mix(c.rgb, viva, marca), c.a) * COLOR;
}
"""

@export_group("Enjambre")
@export var cantidad_inicial := 2
@export var cantidad_maxima := 14
@export var radio_activacion := 1100.0      # el enjambre despierta cuando el jugador se acerca

@export_group("Atasco")
@export var radio_atasco := 220.0           # moverse menos que esto = "estar atascado"
@export var tiempo_atasco := 4.0            # segundos atascado antes de que empiece a crecer
@export var intervalo_crecimiento := 1.5    # segundos entre crías (baja a ~40% al crecer)
@export var se_disipan := true
@export var tiempo_calma := 5.0             # segundos avanzando antes de empezar a disiparse

@export_group("Arañas")
@export var velocidad := 120.0
@export var dano := 6
@export var escala := 3.0
@export var aumento_velocidad := 0.5        # +50 % de velocidad con el enjambre al máximo
@export var hoja: Texture2D                 # opcional: si está vacío se carga RUTA_HOJA

var aranias: Array[AraniaViral] = []
var jugador: Jugador
var material_enjambre: ShaderMaterial
var textura: Texture2D
var activo := false
var ancla := Vector2.ZERO
var tiempo_quieto := 0.0
var tiempo_sin_atasco := 0.0
var cronometro := 0.0
var intensidad := 0.0


func _ready() -> void:
	textura = hoja if hoja != null else load(RUTA_HOJA) as Texture2D
	if textura == null:
		push_warning("EnjambreViral: no se encontró " + RUTA_HOJA)
	var sombreador := Shader.new()
	sombreador.code = CODIGO_SHADER
	material_enjambre = ShaderMaterial.new()
	material_enjambre.shader = sombreador


func _physics_process(delta: float) -> void:
	if not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador") as Jugador
		if jugador == null:
			return
	var cerca := global_position.distance_to(jugador.global_position) <= radio_activacion
	if cerca and not activo:
		_despertar()
	if not activo:
		return
	if cerca:
		_vigilar_atasco(delta)
	_actualizar_intensidad(delta)


func _despertar() -> void:
	activo = true
	ancla = jugador.global_position
	for i in cantidad_inicial:
		_crear_arania(global_position + Vector2(randf_range(-80.0, 80.0), -10.0), false)


func _vigilar_atasco(delta: float) -> void:
	if jugador.global_position.distance_to(ancla) > radio_atasco:
		ancla = jugador.global_position       # se movió: empieza a contar de nuevo
		tiempo_quieto = 0.0
	else:
		tiempo_quieto += delta

	if tiempo_quieto >= tiempo_atasco:
		tiempo_sin_atasco = 0.0
		cronometro += delta
		var intervalo := lerpf(intervalo_crecimiento, intervalo_crecimiento * 0.4, intensidad)
		if cronometro >= intervalo:
			cronometro = 0.0
			_multiplicar()
	else:
		cronometro = 0.0
		tiempo_sin_atasco += delta
		if se_disipan and tiempo_sin_atasco >= tiempo_calma and aranias.size() > cantidad_inicial:
			tiempo_sin_atasco = tiempo_calma - 2.0     # una araña cada 2 s
			_disipar_una()


func _multiplicar() -> void:
	if aranias.size() >= cantidad_maxima:
		return
	var origen := global_position
	if not aranias.is_empty():
		var madre: AraniaViral = aranias.pick_random()
		origen = madre.global_position      # "se multiplican": brotan de otra araña
	_crear_arania(origen + Vector2(randf_range(-30.0, 30.0), -20.0), true)


func _disipar_una() -> void:
	if aranias.is_empty():
		return
	var a: AraniaViral = aranias.pick_random()
	a.disolver()


func _crear_arania(pos: Vector2, con_efecto: bool) -> void:
	var a := AraniaViral.new()
	a.velocidad = velocidad
	a.dano = dano
	a.configurar(material_enjambre, textura, escala)
	add_child(a)
	a.global_position = pos
	a.murio.connect(_on_arania_murio)
	for otra in aranias:                    # las arañas no chocan entre ellas
		a.add_collision_exception_with(otra)
		otra.add_collision_exception_with(a)
	aranias.append(a)
	a.factor_velocidad = 1.0 + aumento_velocidad * intensidad
	if con_efecto:
		a.nacer()
	crecio.emit(aranias.size())


func _on_arania_murio(arania: AraniaViral) -> void:
	aranias.erase(arania)


func _actualizar_intensidad(delta: float) -> void:
	var meta := 0.0
	if cantidad_maxima > cantidad_inicial:
		meta = clampf(float(aranias.size() - cantidad_inicial) / float(cantidad_maxima - cantidad_inicial), 0.0, 1.0)
	intensidad = move_toward(intensidad, meta, delta * 0.6)
	material_enjambre.set_shader_parameter("intensidad", intensidad)
	for a in aranias:
		a.factor_velocidad = 1.0 + aumento_velocidad * intensidad
