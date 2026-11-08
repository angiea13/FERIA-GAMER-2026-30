class_name Jugador
extends CharacterBody2D

#Constantes
#Movimiento
const SPEED = 450.0
const JUMP_VELOCITY = -600.0
const Maximo_Num_Saltos=2
#Relacion con las paredes
const VELOCIDAD_DESLIZAR = 110.0
const EMPUJE_PARED = 500.0
#Temporizadores
#Salto
const COYOTE_TIEMPO = 0.10
#Deslizamiento
const COYOTE_TIEMPO_desliz = 0.2
#Salto de pared
const BLOQUEO_PARED = 0.2
#Ataque
const ANIM_ATAQUE = "atacando"
const TIEMP_ULTI_ATAC=1.0
const BUFFER_ATAQUE = 0.15
const RADIO_CORTE = 30.0
const MAXIMO_ATAQUE=3
#Variables
#Atributos del personaje
var vida = Vida.new(50)
#Ataque
var atacando := false
var numero_ataque:=0
#
var en_telarana:=false
#Funcion Ataque
var colision_ataque: CollisionPolygon2D
var ya_golpeados: Array = []
##Telaranas
var telarana_actual: Telarana = null
#Dash
var direccion_dash = 1
var dash_arriba=false
#Salto
var num_saltos=Maximo_Num_Saltos
var ya_paso_salto=false
##Efectos
var Time_Actual_Dupli: float = 0
var Time_Dupli: float = 0.05
var Time_Life_Dupli: float = 0.2
#Temporizadores
#Salto
var coyote_restante := 0.0
var jump_buffer_restante := 0.0
#Deslizamiento
var coyote_restante_desliz := 0.0
#Salto de pared
var bloqueo_control := 0.0
#Teletransporte
var tiempo_teletranporte=2
var tiempo_teletransporte_ant=2
var en_impulso:bool=false
#Impulso:
var tiempo_impulso:float=0.0
#Temporizadores Ataque
var tiempo_ataque := 0.0
var buffer_ataque := 0.0
var ultimo_ataque:=0.0
#Daño recibido
var invulnerable := 0.0
var muerto := false

#Variables externas
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var slash_area: Area2D = $Slash_Area
@onready var colision_derecha: CollisionPolygon2D = $Slash_Area/Colision_Derecha
@onready var colision_izquierda: CollisionPolygon2D = $Slash_Area/Colision_Izquierda
@onready var dash: Dash = $Dash
func detener_sonidos():
	for nodo in get_children():
		if nodo is AudioStreamPlayer:
			nodo.stop()
func reproducir_sonido(sonido:AudioStreamPlayer):
	if sonido.playing:
		return
	detener_sonidos()
	sonido.play()
func _ready():
	colision_derecha.disabled = true
	colision_izquierda.disabled = true
	colision_ataque = colision_derecha
	dash.configurar(1)
	#UtilsGlobal.load_game()
func _telarana():
	if en_telarana:
		invulnerable=0.4
		return true
	return false
func saltos(delta,suma,resta):
	if (not is_on_floor() and not Jump_Slide())   and !ya_paso_salto:
		num_saltos=1
		ya_paso_salto=true
	if suma!=0:
		num_saltos+=suma
		if num_saltos>Maximo_Num_Saltos:
			num_saltos=Maximo_Num_Saltos
		return
	elif resta!=0:
		num_saltos-=resta
		if num_saltos<0:
			num_saltos=0
		return
	
func impulso(delta):
   #Impulso
	if en_impulso:
		if !$sonido_burbuja.playing:
			reproducir_sonido($sonido_burbuja)
		tiempo_impulso-=delta
		dash.recuperar()
		num_saltos=1
		move_and_slide()
		if tiempo_impulso<=0:
			en_impulso=false
		return true
	return false
func procesar_dash(delta):
	#Dash
	if Input.is_action_just_pressed("hacer_dash"):
		
		if Deslizarse():
			dash_arriba=true
		var dir := Input.get_axis("move_left", "move_right")
		if dir != 0:
			direccion_dash = sign(dir)
		dash.intentar(direccion_dash)
		if dash.activo:
			reproducir_sonido($sonido_dash)
			terminar_ataque()
			invulnerable+=0.2
	if dash.activo:
		if !Deslizarse():
			if !dash_arriba:
				velocity = Vector2(dash.direccion * dash.velocidad, 0)
		else:
			if !dash_arriba:
				velocity = Vector2(dash.direccion * dash.velocidad, 0)
			else:
				velocity = Vector2(0,-dash.velocidad/3.5)
				dash_arriba=true
		if Time_Actual_Dupli >= Time_Dupli:
			Time_Actual_Dupli = 0
			crear_duplicado()
		
		move_and_slide()
		_update_animation(0.0)
		return true
	return false
func todo_relacionado_a_saltos(delta):
	 # Gravedad
	if not is_on_floor():
		coyote_restante -= delta
		velocity += get_gravity() * delta
		if (Deslizarse() and velocity.y > 0):
			if !$sonido_deslizar.playing:
				reproducir_sonido($sonido_deslizar)
			velocity.y = min(velocity.y, VELOCIDAD_DESLIZAR)
			coyote_restante_desliz-=delta
			if !dash_arriba:
				dash.recuperar()
	else:
		if ya_paso_salto:
			if !$sonido_aterrizar.playing:
				reproducir_sonido($sonido_aterrizar)
		coyote_restante = COYOTE_TIEMPO
		dash.recuperar()
		dash_arriba=false
		coyote_restante_desliz=COYOTE_TIEMPO
		ya_paso_salto=false
		saltos(delta,2,0)
	# Jump buffer
	if Input.is_action_just_pressed("jump"):
		jump_buffer_restante = 0.15
	else:
		jump_buffer_restante = max(jump_buffer_restante - delta, 0)

   # Salto de pared
	if not is_on_floor() and Jump_Slide() and jump_buffer_restante > 0:
		if !$sonido_saltar_muro.playing:
			reproducir_sonido($sonido_saltar_muro)
		ya_paso_salto=false
		saltos(delta,1,0)
		velocity.y = JUMP_VELOCITY
		velocity.x = -direccion_dash * EMPUJE_PARED
		direccion_dash = -direccion_dash
		bloqueo_control = BLOQUEO_PARED
		dash.recuperar()
		dash_arriba=false
		jump_buffer_restante = 0
	# Doble Salto
	elif not is_on_floor() and num_saltos>0 and Input.is_action_just_pressed("jump"):
		if !$sonido_doble_salto.playing:
			reproducir_sonido($sonido_doble_salto)
		dash.recuperar()
		velocity.y=1.2*JUMP_VELOCITY
		saltos(delta,0,1)
	# Salto normal
	elif jump_buffer_restante > 0 and coyote_restante > 0:
		if !$sonido_salto.playing:
			reproducir_sonido($sonido_salto)
		saltos(delta,0,1)
		velocity.y = JUMP_VELOCITY
		coyote_restante = 0
		jump_buffer_restante = 0
	# Salto corto
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.6
func teletransporte_en_phisycs(delta):
	if telarana_actual:
		
		if Input.is_action_just_pressed("ir_siguiente") and tiempo_teletranporte>0.4:
			if !$sonido_telarana.playing:
				reproducir_sonido($sonido_telarana)
			teletransportar(telarana_actual.siguiente)
			saltos(delta,1,0)
			tiempo_teletranporte=0
			tiempo_teletransporte_ant=0
		elif Input.is_action_just_pressed("ir_anterior") and tiempo_teletransporte_ant>0.4:
			if !$sonido_telarana.playing:
				reproducir_sonido($sonido_telarana)
			teletransportar(telarana_actual.anterior)
			saltos(delta,1,0)
			tiempo_teletransporte_ant=0
func movimiento_horizontal(delta):
	
	var direction := Input.get_axis("move_left", "move_right")
	if bloqueo_control <= 0:
		if direction:
			velocity.x = direction * SPEED
			direccion_dash = sign(direction)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
func ataque_combo():
	numero_ataque+=1
	if numero_ataque>=MAXIMO_ATAQUE:
		numero_ataque=0
func ataque_en_phisycs(delta):
	 # Ataque
	if Input.is_action_just_pressed("atacar"):
		buffer_ataque = BUFFER_ATAQUE
	else:
		buffer_ataque -= delta
	if buffer_ataque > 0 and not atacando:
		reproducir_sonido($sonido_atacar)
		empezar_ataque()
		ataque_combo()
		
func direccion_ray_casts(delta):
	$Deslizarse.target_position.x = abs($Deslizarse.target_position.x) * direccion_dash
	$Brincar.target_position.x = abs($Brincar.target_position.x) * direccion_dash
	$Revisar_Esquinas.target_position.x = abs($Revisar_Esquinas.target_position.x) * direccion_dash
func _physics_process(delta: float) -> void:
	Time_Actual_Dupli += delta
	tiempo_teletranporte+=delta
	tiempo_teletransporte_ant+=delta
	bloqueo_control-=delta
	invulnerable = maxf(invulnerable - delta, 0.0)
	if not atacando:
		ultimo_ataque += delta
		if ultimo_ataque >= TIEMP_ULTI_ATAC:
			numero_ataque = 0
	if _telarana():
		return
	if Input.is_action_just_pressed("Guardar Partida"):
		UtilsGlobal.save_game()
	#Impulso
	if  impulso(delta):
		return
	if procesar_dash(delta):
		return
   # Gravedad
	todo_relacionado_a_saltos(delta)
	# Teletransporte Telarana
	teletransporte_en_phisycs(delta)
	# Movimiento horizontal
	movimiento_horizontal(delta)
	# Ataque
	ataque_en_phisycs(delta)
	direccion_ray_casts(delta)
	move_and_slide()
	procesar_ataque(delta)
	_update_animation(direccion_dash)

func _update_animation(direction: float) -> void:
	sprite.flip_h = direccion_dash < 0
	if en_telarana:
		return
	if atacando:
		if numero_ataque==1:
			sprite.play("atacando")
		elif numero_ataque==2:
			sprite.play("atacando_2")
		else:
			sprite.play("atacando_3")
	elif not is_on_floor():
		if Deslizarse():
			sprite.play("deslizarse")
		elif velocity.y < 0:
			sprite.play("jump")
		else:
			sprite.play("falling")
	elif is_on_floor() and abs(velocity.x) > 10:
		sprite.play("moving")
		if !$sonido_correr.playing:
			reproducir_sonido($sonido_correr)
	else:
		sprite.play("idle")
		$sonido_correr.stop()
func empezar_ataque() -> void:
	atacando = true
	buffer_ataque = 0
	ya_golpeados.clear()
	tiempo_ataque = duracion_animacion(ANIM_ATAQUE)
	sprite.stop()
	sprite.play(ANIM_ATAQUE)

	actualizar_colision_ataque()

var delay: float = 0.0
func procesar_ataque(delta: float) -> void:
	if not atacando:
		return
	tiempo_ataque -= delta
	actualizar_colision_ataque()
	for cuerpo in slash_area.get_overlapping_bodies():
		golpear(cuerpo)
	for area in slash_area.get_overlapping_areas():
		golpear(area)
	var puntos := puntos_colision()
	delay=max(delay-delta,0)
	if delay==0:
		for t in get_tree().get_nodes_in_group("telaranas"):
			for p in puntos:
				if t.toca_hilo(p, RADIO_CORTE):
					t.cortar()
					delay=1.5
					break
			if delay>0:
				break

	if tiempo_ataque <= 0:
		terminar_ataque()
func actualizar_colision_ataque() -> void:
	var nueva := colision_derecha if direccion_dash == 1 else colision_izquierda
	if nueva == colision_ataque and not nueva.disabled:
		return
	colision_ataque = nueva
	colision_derecha.set_deferred("disabled", colision_ataque != colision_derecha)
	colision_izquierda.set_deferred("disabled", colision_ataque != colision_izquierda)
	
func golpear(objeto: Node) -> void:
	if objeto == self or objeto in ya_golpeados:
		return
	if not objeto.is_in_group("golpeable"):
		return
	ya_golpeados.append(objeto)            # un golpe por ataque a cada cosa
	if objeto.has_method("recibir_golpe"):
		objeto.recibir_golpe(Vector2(direccion_dash, 0))
		
func terminar_ataque() -> void:
	atacando = false
	ultimo_ataque=0.0
	colision_derecha.set_deferred("disabled", true)
	colision_izquierda.set_deferred("disabled", true)


func duracion_animacion(nombre: String) -> float:
	var frames := sprite.sprite_frames
	var total := 0.0
	for i in frames.get_frame_count(nombre):
		total += frames.get_frame_duration(nombre, i)
	return total / frames.get_animation_speed(nombre)

func puntos_colision() -> Array:
	var resultado := []
	var centro := Vector2.ZERO
	for p in colision_ataque.polygon:
		resultado.append(colision_ataque.global_transform * p)
		centro += p
	if colision_ataque.polygon.size() > 0:
		resultado.append(colision_ataque.global_transform * (centro / colision_ataque.polygon.size()))
	return resultado


func teletransportar(destino: Telarana) -> void:
	if destino == null or en_telarana:
		return
	en_telarana = true
	velocity = Vector2.ZERO
	var inicio = global_position
	var fin = destino.global_position + Vector2(0, -16)
	sprite.play("entrar")
	await sprite.animation_finished
	sprite.play("viajar")
	var tween = create_tween()
	tween.tween_property(self, "global_position", fin, 0.8)
	telarana_actual = destino
	await tween.finished
	sprite.play_backwards("entrar")
	await sprite.animation_finished
	telarana_actual = destino
	dash.recuperar()
	en_telarana = false

func crear_duplicado():
	var duplicado: AnimatedSprite2D = sprite.duplicate()
	duplicado.material = sprite.material.duplicate()
	duplicado.material.set_shader_parameter("opacity", 0.3)
	duplicado.material.set_shader_parameter("r", 0.0)
	duplicado.material.set_shader_parameter("g", 0.0)
	duplicado.material.set_shader_parameter("b", 0.8)
	duplicado.material.set_shader_parameter("mix_color", 0.7)
	get_parent().add_child(duplicado)
	duplicado.global_position = sprite.global_position
	duplicado.global_scale = sprite.global_scale
	duplicado.pause()
	await get_tree().create_timer(Time_Life_Dupli).timeout
	duplicado.queue_free()
func Deslizarse():
	$Deslizarse.force_raycast_update()

	if $Deslizarse.is_colliding():
		return true

	return false


func Jump_Slide():
	return $Brincar.is_colliding()


# ---------------- Daño y muerte ----------------
func recibir_dano(cantidad: int, origen_x: float = 0.0) -> void:
	if muerto or invulnerable > 0.0:
		return
	vida._recibir_dano(cantidad)
	invulnerable = 1.0
	bloqueo_control = 0.25
	var dir := signf(global_position.x - origen_x)
	if dir == 0.0:
		dir = -float(direccion_dash)
	velocity = Vector2(dir * 450.0, -350.0)
	parpadear()
	if vida.muerte:
		morir()


func parpadear() -> void:
	# El shader del sprite sobreescribe COLOR, por eso se parpadea con su
	# parámetro "opacity" (modulate no tendría efecto).
	var t := create_tween().set_loops(5)
	t.tween_callback(func(): sprite.material.set_shader_parameter("opacity", 0.35))
	t.tween_interval(0.1)
	t.tween_callback(func(): sprite.material.set_shader_parameter("opacity", 1.0))
	t.tween_interval(0.1)


func matar() -> void:
	# Muerte instantánea (caídas al vacío), ignora la invulnerabilidad.
	if muerto:
		return
	vida._recibir_dano(vida.vida)
	morir()


func morir() -> void:
	if muerto:
		return
	if !$sonido_muerte.playing:
		reproducir_sonido($sonido_muerte)
	muerto = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	await get_tree().create_timer(0.8).timeout
	get_tree().reload_current_scene()
