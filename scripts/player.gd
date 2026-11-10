extends CharacterBody3D

@export var move_speed := 4.0
@export var look_sensitivity := 0.004
@export var gravity := 18.0

var camera: Camera3D
var interaction_ray: RayCast3D
var joystick_vector := Vector2.ZERO
var move_touch_id := -1
var look_touch_id := -1
var move_origin := Vector2.ZERO
var move_current := Vector2.ZERO
var last_look := Vector2.ZERO
var pitch := 0.0

func _ready() -> void:
    camera = get_node("Camera3D")
    interaction_ray = camera.get_node("InteractionRay")
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        _rotate_camera(event.relative)
    elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    elif event is InputEventScreenTouch:
        var w := get_viewport().get_visible_rect().size.x
        if event.pressed:
            if event.position.x < w * 0.48 and move_touch_id == -1:
                move_touch_id = event.index
                move_origin = event.position
                move_current = event.position
            elif event.position.x >= w * 0.48 and look_touch_id == -1:
                look_touch_id = event.index
                last_look = event.position
        else:
            if event.index == move_touch_id:
                move_touch_id = -1
                joystick_vector = Vector2.ZERO
            if event.index == look_touch_id:
                look_touch_id = -1
    elif event is InputEventScreenDrag:
        if event.index == move_touch_id:
            move_current = event.position
            var delta := (move_current - move_origin) / 75.0
            joystick_vector = delta.limit_length(1.0)
        elif event.index == look_touch_id:
            _rotate_camera(event.relative)

func _rotate_camera(delta: Vector2) -> void:
    rotate_y(-delta.x * look_sensitivity)
    pitch = clamp(pitch - delta.y * look_sensitivity, deg_to_rad(-75), deg_to_rad(75))
    camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
    var input_vec := joystick_vector
    input_vec.y = -input_vec.y
    input_vec.x += float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
    input_vec.y += float(Input.is_key_pressed(KEY_W)) - float(Input.is_key_pressed(KEY_S))
    input_vec = input_vec.limit_length(1.0)

    var direction := (transform.basis * Vector3(input_vec.x, 0, -input_vec.y)).normalized()
    velocity.x = direction.x * move_speed
    velocity.z = direction.z * move_speed
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0
    move_and_slide()

func interact() -> void:
    interaction_ray.force_raycast_update()
    if interaction_ray.is_colliding():
        var target := interaction_ray.get_collider()
        if target.has_meta("item_name"):
            var item_name: String = target.get_meta("item_name")
            get_parent().show_message("Kamu memeriksa: " + item_name)
        else:
            get_parent().show_message("Tidak ada barang yang bisa diambil di sini.")
    else:
        get_parent().show_message("Dekati rak atau barang untuk berinteraksi.")
