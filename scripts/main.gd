extends Node3D

const PlayerScript = preload("res://scripts/player.gd")

var player: CharacterBody3D
var joystick_touch := -1
var joystick_origin := Vector2.ZERO
var joystick_vector := Vector2.ZERO
var look_touch := -1
var last_look_pos := Vector2.ZERO
var game_started := false
var hud: CanvasLayer
var menu_layer: Control
var joystick_base: ColorRect
var joystick_knob: ColorRect
var interact_button: Button
var status_label: Label

func _ready() -> void:
    _build_world()
    _build_player()
    _build_ui()
    _show_main_menu()

func _build_world() -> void:
    var world_env := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    env.sky.sky_material = ProceduralSkyMaterial.new()
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.72, 0.78, 0.84)
    env.ambient_light_energy = 0.65
    world_env.environment = env
    add_child(world_env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -32, 0)
    sun.light_energy = 1.15
    sun.shadow_enabled = true
    add_child(sun)

    _box("Tanah", Vector3(0, -0.15, 0), Vector3(34, 0.3, 34), Color(0.34, 0.48, 0.28))
    _box("Lantai warung", Vector3(0, 0.05, 0), Vector3(7, 0.2, 6), Color(0.66, 0.57, 0.43))

    # Dinding belakang dan samping; bagian depan sengaja terbuka.
    _box("Dinding belakang", Vector3(0, 1.75, -2.9), Vector3(7, 3.5, 0.2), Color(0.78, 0.69, 0.54))
    _box("Dinding kiri", Vector3(-3.4, 1.75, 0), Vector3(0.2, 3.5, 5.8), Color(0.56, 0.34, 0.20))
    _box("Dinding kanan", Vector3(3.4, 1.75, 0), Vector3(0.2, 3.5, 5.8), Color(0.56, 0.34, 0.20))
    _box("Atap", Vector3(0, 3.55, 0), Vector3(7.5, 0.22, 6.5), Color(0.55, 0.19, 0.12))

    # Meja kasir dan rak sederhana, bukan geometri placeholder kosong.
    _box("Meja kasir", Vector3(0, 0.65, 1.75), Vector3(2.3, 1.1, 0.75), Color(0.42, 0.24, 0.13))
    _box("Permukaan meja", Vector3(0, 1.23, 1.75), Vector3(2.4, 0.08, 0.82), Color(0.72, 0.52, 0.30))
    for side in [-1, 1]:
        var x := float(side) * 2.65
        _box("Rak bawah", Vector3(x, 0.65, -0.15), Vector3(0.55, 1.3, 4.3), Color(0.38, 0.23, 0.13))
        for shelf_y in [0.45, 1.0, 1.55, 2.1]:
            _box("Papan rak", Vector3(x, shelf_y, -0.15), Vector3(0.85, 0.09, 4.4), Color(0.64, 0.42, 0.23))
        for row in range(3):
            for col in range(5):
                var product_color: Color = [Color(0.86,0.22,0.12), Color(0.95,0.72,0.12), Color(0.18,0.48,0.76), Color(0.24,0.65,0.34)][(row + col) % 4]
                _box("Kemasan dagangan", Vector3(x + float(side) * 0.12, 0.72 + float(row) * 0.55, -1.7 + float(col) * 0.72), Vector3(0.28, 0.36, 0.28), product_color)

    # Beberapa rumah sederhana di luar warung untuk memberi konteks lingkungan.
    _house(Vector3(-8, 0, -5), Color(0.83, 0.63, 0.42))
    _house(Vector3(8, 0, -7), Color(0.72, 0.77, 0.66))
    _house(Vector3(-9, 0, 7), Color(0.72, 0.48, 0.38))
    _box("Jalan lingkungan", Vector3(0, 0.01, 7.8), Vector3(34, 0.08, 3.2), Color(0.23, 0.25, 0.27))

func _house(pos: Vector3, wall_color: Color) -> void:
    _box("Rumah tetangga", pos + Vector3(0, 1.1, 0), Vector3(4.2, 2.2, 3.5), wall_color)
    _box("Atap rumah", pos + Vector3(0, 2.45, 0), Vector3(4.7, 0.35, 4.0), Color(0.48, 0.18, 0.14))

func _box(label: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = label
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.position = pos
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.9
    mesh_instance.material_override = material
    add_child(mesh_instance)

    var body := StaticBody3D.new()
    body.position = pos
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    add_child(body)
    return mesh_instance

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.set_script(PlayerScript)
    player.position = Vector3(0, 0.2, 4.6)
    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.32
    capsule.height = 1.75
    collider.shape = capsule
    collider.position.y = 0.88
    player.add_child(collider)
    add_child(player)

func _build_ui() -> void:
    hud = CanvasLayer.new()
    add_child(hud)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud.add_child(root)

    joystick_base = ColorRect.new()
    joystick_base.color = Color(0.08, 0.08, 0.08, 0.35)
    joystick_base.size = Vector2(132, 132)
    joystick_base.position = Vector2(34, -166)
    joystick_base.anchor_top = 1.0
    joystick_base.anchor_bottom = 1.0
    root.add_child(joystick_base)

    joystick_knob = ColorRect.new()
    joystick_knob.color = Color(0.88, 0.88, 0.88, 0.75)
    joystick_knob.size = Vector2(58, 58)
    joystick_knob.position = Vector2(37, 37)
    joystick_base.add_child(joystick_knob)

    interact_button = Button.new()
    interact_button.text = "INTERAKSI"
    interact_button.size = Vector2(132, 58)
    interact_button.anchor_left = 1.0
    interact_button.anchor_right = 1.0
    interact_button.anchor_top = 1.0
    interact_button.anchor_bottom = 1.0
    interact_button.position = Vector2(-164, -94)
    interact_button.pressed.connect(_interact)
    root.add_child(interact_button)

    var sprint_button := Button.new()
    sprint_button.text = "LARI"
    sprint_button.size = Vector2(86, 48)
    sprint_button.anchor_left = 1.0
    sprint_button.anchor_right = 1.0
    sprint_button.anchor_top = 1.0
    sprint_button.anchor_bottom = 1.0
    sprint_button.position = Vector2(-164, -154)
    sprint_button.button_down.connect(func(): player.sprinting = true)
    sprint_button.button_up.connect(func(): player.sprinting = false)
    root.add_child(sprint_button)

    status_label = Label.new()
    status_label.text = "Warung Kita Simulator • Versi 0.2"
    status_label.position = Vector2(18, 14)
    status_label.add_theme_color_override("font_color", Color.WHITE)
    status_label.add_theme_font_size_override("font_size", 20)
    root.add_child(status_label)

    menu_layer = Control.new()
    menu_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud.add_child(menu_layer)

func _show_main_menu() -> void:
    for child in menu_layer.get_children():
        child.queue_free()
    var shade := ColorRect.new()
    shade.color = Color(0.04, 0.06, 0.07, 0.88)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_layer.add_child(shade)

    var panel := VBoxContainer.new()
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.position = Vector2(-190, -190)
    panel.size = Vector2(380, 380)
    panel.add_theme_constant_override("separation", 14)
    menu_layer.add_child(panel)

    var title := Label.new()
    title.text = "WARUNG KITA\\nSIMULATOR"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color(1.0, 0.78, 0.35))
    panel.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Simulator warung tradisional Indonesia"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    panel.add_child(subtitle)

    _menu_button(panel, "MULAI GAME", _start_game)
    _menu_button(panel, "PENGATURAN", _show_settings)
    _menu_button(panel, "TENTANG GAME", _show_about)

    var credit := Label.new()
    credit.text = "Dikembangkan oleh Aditia Hermawan"
    credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    panel.add_child(credit)

func _menu_button(parent: VBoxContainer, caption: String, action: Callable) -> void:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size = Vector2(300, 48)
    button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    button.pressed.connect(action)
    parent.add_child(button)

func _start_game() -> void:
    game_started = true
    menu_layer.visible = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _show_settings() -> void:
    _show_simple_panel("PENGATURAN", "Kontrol sentuh aktif. Sensitivitas kamera dan kualitas grafis akan ditambahkan pada tahap berikutnya.")

func _show_about() -> void:
    _show_simple_panel("TENTANG GAME", "Warung Kita Simulator\\nGame simulasi warung offline.\\nDikembangkan oleh Aditia Hermawan.")

func _show_simple_panel(title_text: String, body_text: String) -> void:
    for child in menu_layer.get_children():
        child.queue_free()
    var shade := ColorRect.new()
    shade.color = Color(0.04, 0.06, 0.07, 0.9)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_layer.add_child(shade)
    var panel := VBoxContainer.new()
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.position = Vector2(-220, -130)
    panel.size = Vector2(440, 260)
    menu_layer.add_child(panel)
    var title := Label.new()
    title.text = title_text
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 28)
    panel.add_child(title)
    var body := Label.new()
    body.text = body_text
    body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.custom_minimum_size = Vector2(420, 110)
    panel.add_child(body)
    _menu_button(panel, "KEMBALI", _show_main_menu)

func _interact() -> void:
    if game_started:
        status_label.text = "Belum ada objek interaksi di tahap fondasi."

func _input(event: InputEvent) -> void:
    if not game_started:
        return

    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x < get_viewport().get_visible_rect().size.x * 0.45 and joystick_touch == -1:
                joystick_touch = event.index
                joystick_origin = event.position
                _update_joystick(event.position)
            elif event.position.x >= get_viewport().get_visible_rect().size.x * 0.45 and look_touch == -1:
                look_touch = event.index
                last_look_pos = event.position
        else:
            if event.index == joystick_touch:
                joystick_touch = -1
                joystick_vector = Vector2.ZERO
                player.set_move_input(Vector2.ZERO)
                joystick_knob.position = Vector2(37, 37)
            if event.index == look_touch:
                look_touch = -1

    elif event is InputEventScreenDrag:
        if event.index == joystick_touch:
            _update_joystick(event.position)
        elif event.index == look_touch:
            player.add_look_input(event.relative)
            last_look_pos = event.position

func _update_joystick(position: Vector2) -> void:
    var center := joystick_base.global_position + joystick_base.size * 0.5
    var offset := (position - center).limit_length(48.0)
    joystick_vector = offset / 48.0
    player.set_move_input(Vector2(joystick_vector.x, joystick_vector.y))
    joystick_knob.position = Vector2(37, 37) + offset
