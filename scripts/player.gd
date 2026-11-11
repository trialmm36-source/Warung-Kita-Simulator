extends CharacterBody3D

@export var move_speed: float = 4.0
@export var sprint_multiplier: float = 1.55
@export var look_sensitivity: float = 0.003
@export var gravity: float = 18.0

var move_input := Vector2.ZERO
var look_delta := Vector2.ZERO
var sprinting := false
var camera_pivot: Node3D
var camera: Camera3D

func _ready() -> void:
    camera_pivot = Node3D.new()
    camera_pivot.position = Vector3(0, 1.62, 0)
    add_child(camera_pivot)

    camera = Camera3D.new()
    camera.current = true
    camera.fov = 78.0
    camera_pivot.add_child(camera)

func set_move_input(value: Vector2) -> void:
    move_input = value.limit_length(1.0)

func add_look_input(delta: Vector2) -> void:
    look_delta += delta

func _physics_process(delta: float) -> void:
    rotate_y(-look_delta.x * look_sensitivity)
    camera_pivot.rotation.x = clamp(
        camera_pivot.rotation.x - look_delta.y * look_sensitivity,
        deg_to_rad(-75.0), deg_to_rad(75.0)
    )
    look_delta = Vector2.ZERO

    var input_dir := Vector3(move_input.x, 0.0, move_input.y)
    var direction := (global_transform.basis * input_dir).normalized()
    var speed := move_speed * (sprint_multiplier if sprinting else 1.0)

    if direction.length() > 0.01:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0.0, move_speed * 5.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, move_speed * 5.0 * delta)

    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0

    move_and_slide()
