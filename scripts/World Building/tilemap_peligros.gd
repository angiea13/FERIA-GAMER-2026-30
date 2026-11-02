extends TileMapLayer
# Capa de terreno con tiles peligrosos (pinchos). Los tiles con el dato
# personalizado "dano" > 0 lastiman al jugador cuando sus pies los toca
func _physics_process(_delta: float) -> void:
    var j := get_tree().get_first_node_in_group("jugador") as Jugador
    if j == null or j.muerto:
        return
    var centro: Vector2 = j.get_node("CollisionShape2D").global_position
    for desfase in [Vector2(0, 50), Vector2(-22, 50), Vector2(22, 50), Vector2(0, 20),
    Vector2(0, -50),Vector2(-22, -50),  Vector2(22, -50),Vector2(0, -20)]:
        var celda := local_to_map(to_local(centro + desfase))
        var datos := get_cell_tile_data(celda)
        if datos == null:
            continue
        var dano: int = datos.get_custom_data("dano")/5
        if dano > 0:
            j.recibir_dano(dano, map_to_local(celda).x)
            return
