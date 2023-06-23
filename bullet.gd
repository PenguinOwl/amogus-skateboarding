extends Area3D

@onready var mesh_instance_3d = $MeshInstance3D

const CRIT = preload("res://bullet_crit.tres")
const NORMAL = preload("res://bullet_normal.tres")

var velocity = Vector3(0, 0, -1)
var timer = 4.0
var max_distance = 0.0
var layers = 4
var is_crit = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _physics_process(delta):
	timer -= delta
	max_distance -= velocity.length() * delta
	if timer < 0 || max_distance < 0:
		get_parent().remove_child(self)
	transform.origin += velocity * delta

func _on_body_entered(body):
	# if body is CharacterBody3D:
	# 	print("hit")
	queue_free()
	
func _ready():
	mesh_instance_3d.layers = layers
	if is_crit:
		mesh_instance_3d.set_surface_override_material(0, CRIT)
