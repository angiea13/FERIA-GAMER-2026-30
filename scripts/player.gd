class_name Jugador
extends CharacterBody2D
#Variables externas
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var slash_area: Area2D = $Slash_Area
@onready var colision_derecha: CollisionPolygon2D = $Slash_Area/Colision_Derecha
@onready var colision_izquierda: CollisionPolygon2D = $Slash_Area/Colision_Izquierda
#Atributos del personaje
var vida = Vida.new(100)
#Movimiento
const SPEED = 500.0
const JUMP_VELOCITY = -650.0
#Relacion con las paredes
const VELOCIDAD_DESLIZAR = 120.0 
const EMPUJE_PARED = 600.0        
#Temporizadores
#Salto
const COYOTE_TIEMPO = 0.2
var coyote_restante := 0.0
var jump_buffer_restante := 0.0
#Deslizamiento
const COYOTE_TIEMPO_desliz = 0.2
var coyote_restante_desliz := 0.0
#Salto de pared
const BLOQUEO_PARED = 0.30   
var bloqueo_control := 0.0
#Teletransporte
var tiempo_teletranporte=2   
var tiempo_teletransporte_ant=2    
var en_impulso:bool=false
#Impulso:
var tiempo_impulso:float=0.0
#Ataque
const ANIM_ATAQUE = "atacando"       
const BUFFER_ATAQUE = 0.15
const RADIO_CORTE = 30.0
var atacando := false
#Temporizadores Ataque
var tiempo_ataque := 0.0
var buffer_ataque := 0.0
#Funcion Ataque
var colision_ataque: CollisionPolygon2D
var ya_golpeados: Array = []
##Telaranas
var telarana_actual: Telarana = null
##Dash
@onready var dash: Dash = $Dash
var direccion_dash = 1
var dash_arriba=false
##Efectos
var Time_Actual_Dupli: float = 0
var Time_Dupli: float = 0.05
var Time_Life_Dupli: float = 0.2


func _ready():
    colision_derecha.disabled = true
    colision_izquierda.disabled = true
    colision_ataque = colision_derecha
    
    dash.configurar(1)
    UtilsGlobal.load_game()


func _physics_process(delta: float) -> void:
    Time_Actual_Dupli += delta
    tiempo_teletranporte+=delta
    tiempo_teletransporte_ant+=delta
    bloqueo_control-=delta
    if Input.is_action_just_pressed("Guardar Partida"):
        UtilsGlobal.save_game()
    #Impulso
    if en_impulso:
        tiempo_impulso-=delta
        dash.recuperar()
        move_and_slide()
        if tiempo_impulso<=0:
            en_impulso=false
        return
    #Dash
    if Input.is_action_just_pressed("hacer_dash"):
        var dir := Input.get_axis("move_left", "move_right")
        if dir != 0:
            direccion_dash = sign(dir)
        dash.intentar(direccion_dash)
        if dash.activo:
            terminar_ataque()
    if dash.activo:
        if !Deslizarse():
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
        return

   # Gravedad
    if not is_on_floor():
        coyote_restante -= delta
        velocity += get_gravity() * delta
        if (Deslizarse() and velocity.y > 0) or (coyote_restante<COYOTE_TIEMPO and coyote_restante>0):
            velocity.y = min(velocity.y, VELOCIDAD_DESLIZAR)
            coyote_restante_desliz-=delta
            if !dash_arriba:
             dash.recuperar()
    else:
        coyote_restante = COYOTE_TIEMPO
        dash.recuperar()
        dash_arriba=false
        coyote_restante_desliz=COYOTE_TIEMPO
    # Jump buffer
    if Input.is_action_just_pressed("jump"):
        jump_buffer_restante = 0.15
    else:
        jump_buffer_restante = max(jump_buffer_restante - delta, 0)

   # Salto de pared
    if not is_on_floor() and Jump_Slide() and jump_buffer_restante > 0:
        velocity.y = JUMP_VELOCITY
        velocity.x = -direccion_dash * EMPUJE_PARED
        direccion_dash = -direccion_dash
        bloqueo_control = BLOQUEO_PARED
        dash.recuperar()
        dash_arriba=false
        jump_buffer_restante = 0
    # Salto normal
    elif jump_buffer_restante > 0 and coyote_restante > 0:
        velocity.y = JUMP_VELOCITY
        coyote_restante = 0
        jump_buffer_restante = 0
    # Salto corto
    if Input.is_action_just_released("jump") and velocity.y < 0.0:
        velocity.y *= 0.6

    # Teletransporte
    if telarana_actual:
        
        if Input.is_action_just_pressed("ir_siguiente") and tiempo_teletranporte>0.4:
            teletransportar(telarana_actual.siguiente)
            tiempo_teletranporte=0
        elif Input.is_action_just_pressed("ir_anterior") and tiempo_teletransporte_ant>0.4:
            teletransportar(telarana_actual.anterior)
            tiempo_teletranporte=0
    
    # Movimiento horizontal
    var direction := Input.get_axis("move_left", "move_right")
    if bloqueo_control <= 0:
        if direction:
            velocity.x = direction * SPEED
            direccion_dash = sign(direction)
        else:
            velocity.x = move_toward(velocity.x, 0, SPEED)

    # Ataque
    if Input.is_action_just_pressed("atacar"):
        buffer_ataque = BUFFER_ATAQUE
    else:
        buffer_ataque -= delta
    if buffer_ataque > 0 and not atacando:
        empezar_ataque()
  
    $Deslizarse.target_position.x = abs($Deslizarse.target_position.x) * direccion_dash
    $Brincar.target_position.x = abs($Brincar.target_position.x) * direccion_dash
    $Revisar_Esquinas.target_position.x = abs($Revisar_Esquinas.target_position.x) * direccion_dash

    move_and_slide()
    procesar_ataque(delta)
    _update_animation(direction)


func _update_animation(direction: float) -> void:
    sprite.flip_h = direccion_dash < 0
    if atacando and sprite.sprite_frames.has_animation(ANIM_ATAQUE):
        sprite.play(ANIM_ATAQUE)
    elif not is_on_floor():
        if velocity.y < 0:
            sprite.play("jump")
        else:
            sprite.play("falling")
    elif direction:
        sprite.play("moving")
    else:
        sprite.play("idle")
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
                delay=4
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
    if destino == null:
        return
    global_position = destino.global_position + Vector2(0, -16)
    velocity = Vector2.ZERO
    telarana_actual = destino
    dash.recuperar()


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
        print("Detectó: ", $Deslizarse.get_collider())
        return true

    return false


func Jump_Slide():
    return $Brincar.is_colliding()
