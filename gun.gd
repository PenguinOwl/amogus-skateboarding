extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

@onready var meshes = [$Cube, $Cube001, $Cube002, $Cube003, $Cube004, $Cylinder]

func set_visual_layers(layers):
	for mesh in meshes:
		mesh.layers = layers
