extends Node3D

const PLAYER_SCENE := preload("res://scripts/player.gd")

var player: CharacterBody3D
var status_label: Label

func _ready() -> void:
    _make_environment()
    _make_warung()
    _make_neighborhood()
    _make_player()
    _make_ui()

func _material(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 1.0
    return m

func _box(parent: Node3D, name: String, pos: Vector3, size: Vector3, color: Color, collision := true) -> MeshInstance3D:
    var body := StaticBody3D.new() if collision else Node3D.new()
    body.name = name
    body.position = pos
    parent.add_child(body)
    var mesh := BoxMesh.new()
    mesh.size = size
    var visual := MeshInstance3D.new()
    visual.mesh = mesh
    visual.material_override = _material(color)
    body.add_child(visual)
    if collision:
        var shape := CollisionShape3D.new()
        var box := BoxShape3D.new()
        box.size = size
        shape.shape = box
        body.add_child(shape)
    return visual

func _make_environment() -> void:
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.78, 0.82, 0.88)
    env.ambient_light_energy = 0.65
    world.environment = env
    add_child(world)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -30, 0)
    sun.light_energy = 1.0
    sun.shadow_enabled = false
    add_child(sun)

    _box(self, "Tanah_area", Vector3(0, -0.25, 0), Vector3(34, 0.5, 34), Color("#9b927e"))
    _box(self, "Jalan_gang", Vector3(0, 0.02, 5.8), Vector3(34, 0.08, 5.0), Color("#777b78"))
    _box(self, "Trotoar_kecil", Vector3(0, 0.06, 2.9), Vector3(34, 0.12, 0.9), Color("#b9b3a6"))

func _make_warung() -> void:
    var shop := Node3D.new()
    shop.name = "Warung_Kita"
    add_child(shop)
    # Bangunan: tembok belakang/samping, bagian depan terbuka, rangka kayu dan atap seng.
    _box(shop, "Lantai_semen", Vector3(0, 0.12, 0), Vector3(8, 0.24, 6), Color("#aaa69b"))
    _box(shop, "Dinding_belakang", Vector3(0, 1.8, -2.85), Vector3(8, 3.4, 0.3), Color("#d6c8a9"))
    _box(shop, "Dinding_kiri", Vector3(-3.85, 1.8, 0), Vector3(0.3, 3.4, 5.7), Color("#c8b995"))
    _box(shop, "Dinding_kanan", Vector3(3.85, 1.8, 0), Vector3(0.3, 3.4, 5.7), Color("#c8b995"))
    _box(shop, "Panel_kayu_depan_kiri", Vector3(-2.8, 1.15, 2.78), Vector3(2.0, 2.1, 0.18), Color("#93643e"))
    _box(shop, "Panel_kayu_depan_kanan", Vector3(2.8, 1.15, 2.78), Vector3(2.0, 2.1, 0.18), Color("#93643e"))
    _box(shop, "Tiang_kayu_kiri", Vector3(-1.75, 1.8, 2.7), Vector3(0.18, 3.5, 0.18), Color("#70472d"))
    _box(shop, "Tiang_kayu_kanan", Vector3(1.75, 1.8, 2.7), Vector3(0.18, 3.5, 0.18), Color("#70472d"))
    _box(shop, "Atap_seng", Vector3(0, 3.65, 0), Vector3(8.5, 0.18, 6.5), Color("#68757a"))
    _box(shop, "Meja_kasir", Vector3(0, 0.75, 1.0), Vector3(3.0, 1.1, 0.8), Color("#8b5e3c"))
    _box(shop, "Papan_nama", Vector3(0, 3.0, 2.86), Vector3(3.4, 0.55, 0.12), Color("#2d654d"), false)

    # Rak belakang dan produk blok warna sebagai placeholder aset.
    _box(shop, "Rak_belakang", Vector3(0, 1.45, -2.35), Vector3(5.6, 2.3, 0.55), Color("#805638"))
    for y in [0.75, 1.45, 2.15]:
        _box(shop, "Papan_rak", Vector3(0, y, -1.98), Vector3(5.8, 0.09, 0.85), Color("#a8794e"))
    var colors := [Color("#d84b3e"), Color("#e8c64c"), Color("#4b9b73"), Color("#477bb5"), Color("#d98b42")]
    for row in range(3):
        for col in range(9):
            var item := StaticBody3D.new()
            item.name = "Barang_%d_%d" % [row, col]
            item.position = Vector3(-2.45 + col * 0.61, 0.98 + row * 0.7, -1.78)
            item.set_meta("item_name", "Produk warung")
            shop.add_child(item)
            var mesh := MeshInstance3D.new()
            var boxmesh := BoxMesh.new()
            boxmesh.size = Vector3(0.32, 0.38, 0.28)
            mesh.mesh = boxmesh
            mesh.material_override = _material(colors[(row + col) % colors.size()])
            item.add_child(mesh)
            var cs := CollisionShape3D.new()
            var bs := BoxShape3D.new()
            bs.size = boxmesh.size
            cs.shape = bs
            item.add_child(cs)

func _make_neighborhood() -> void:
    # Rumah sederhana di sisi gang; sengaja sedikit dan sederhana untuk menjaga performa.
    var house_colors := [Color("#d8b98d"), Color("#b9c5b2"), Color("#d5aaa0")]
    for i in range(5):
        var z := -9.0 + i * 4.5
        _box(self, "Rumah_kiri_%d" % i, Vector3(-8.5, 1.4, z), Vector3(5.0, 2.8, 3.8), house_colors[i % 3])
        _box(self, "Atap_kiri_%d" % i, Vector3(-8.5, 2.95, z), Vector3(5.5, 0.25, 4.2), Color("#77716b"))
        _box(self, "Rumah_kanan_%d" % i, Vector3(8.5, 1.4, z), Vector3(5.0, 2.8, 3.8), house_colors[(i + 1) % 3])
        _box(self, "Atap_kanan_%d" % i, Vector3(8.5, 2.95, z), Vector3(5.5, 0.25, 4.2), Color("#77716b"))
    # Motor sederhana sebagai siluet dekoratif.
    _box(self, "Motor_badan", Vector3(4.8, 0.48, 4.2), Vector3(1.3, 0.45, 0.5), Color("#253b48"))
    _box(self, "Motor_jok", Vector3(4.75, 0.78, 4.2), Vector3(0.65, 0.16, 0.42), Color("#202326"))

func _make_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.set_script(PLAYER_SCENE)
    player.position = Vector3(0, 0.2, 6.8)

    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.32
    capsule.height = 1.7
    collision.shape = capsule
    collision.position.y = 0.85
    player.add_child(collision)

    var camera := Camera3D.new()
    camera.name = "Camera3D"
    camera.position.y = 1.55
    camera.current = true
    player.add_child(camera)

    var ray := RayCast3D.new()
    ray.name = "InteractionRay"
    ray.target_position = Vector3(0, 0, -2.5)
    ray.enabled = true
    camera.add_child(ray)

    add_child(player)

func _make_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var title := Label.new()
    title.text = "WARUNG KITA  |  Prototype 0.1"
    title.position = Vector2(20, 16)
    title.add_theme_font_size_override("font_size", 22)
    title.add_theme_color_override("font_color", Color.WHITE)
    layer.add_child(title)

    status_label = Label.new()
    status_label.text = "Geser kiri untuk bergerak • Geser kanan untuk melihat"
    status_label.position = Vector2(20, 52)
    status_label.add_theme_font_size_override("font_size", 16)
    status_label.add_theme_color_override("font_color", Color.WHITE)
    layer.add_child(status_label)

    var interact := Button.new()
    interact.text = "INTERAKSI"
    interact.position = Vector2(1040, 590)
    interact.size = Vector2(190, 82)
    interact.add_theme_font_size_override("font_size", 20)
    layer.add_child(interact)
    interact.pressed.connect(player.interact)

func show_message(message: String) -> void:
    if is_instance_valid(status_label):
        status_label.text = message
