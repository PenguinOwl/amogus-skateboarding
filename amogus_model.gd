extends Node3D

var render_model = false
@onready var meshes = [$Sphere, $Sphere001, $Sphere002, $Sphere003, $Cube]
@onready var body_meshes = [$Sphere, $Sphere002, $Sphere003]
@onready var backpack = $Cube
@onready var walk_animation = $WalkAnimation

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var shadow_mode = MeshInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	if render_model:
		shadow_mode = MeshInstance3D.SHADOW_CASTING_SETTING_ON
	for mesh in meshes:
		mesh.cast_shadow = shadow_mode

func set_color(color : Color):
	for body_mesh in body_meshes:
		body_mesh.get_active_material(0).albedo_color = color
	backpack.get_active_material(0).albedo_color = color.darkened(0.4)
