extends CharacterBody3D

@export var type = "chungus"
@export var cap_time = 10
@export var half_capped = false
var authority = 1
var age = 0.0
var sin_timer = 0.0
var cached = 0
@export var interacted = false
@export var track : int
@onready var audio_player = $audio_player
const chungus_noises = [
	preload("res://sounds/piggies.ogg"),
	preload("res://sounds/undertale.ogg"),
	preload("res://sounds/chungus.ogg"),
	preload("res://sounds/astronaut.ogg"),
	preload("res://sounds/pizza.ogg"),
	preload("res://sounds/deez.ogg"),
	preload("res://sounds/femur.ogg"),
	preload("res://sounds/freebird.ogg"),
	preload("res://sounds/sans.ogg"),
	preload("res://sounds/caretaker.ogg"),
	preload("res://sounds/gordon.ogg"),
	preload("res://sounds/dark_souls.ogg"),
	preload("res://sounds/shoenice.ogg"),
	preload("res://sounds/saul.ogg"),
	preload("res://sounds/cena.ogg")
]

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _enter_tree():
	set_multiplayer_authority(1)

func _ready():
	if !multiplayer.is_server():
		return 
	track = randi_range(0, chungus_noises.size() - 1)

func _process(delta):
	print(track)
	if cached != track:
		cached = track
		audio_player.stream = chungus_noises[track]
	sin_timer += delta
	if interacted && audio_player.playing == false:
		audio_player.play(0.0)
	if !multiplayer.is_server():
		return 
	age += delta
	if age > 90 && !half_capped:
		queue_free()
	if age > 150:
		queue_free()

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if position.y < -30:
		queue_free()
	
	move_and_slide()

@rpc("any_peer", "call_local") func remove():
	if is_multiplayer_authority():
		queue_free()

@rpc("any_peer", "call_local") func set_half():
	half_capped = true

@rpc("any_peer", "call_local") func interact():
	interacted = true
