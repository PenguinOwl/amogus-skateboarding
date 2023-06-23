extends Node3D

const Player = preload("res://player.tscn")
const Effigy = preload("res://chungus.tscn")
@onready var address_entry = $CanvasLayer/main_menu/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/address_entry
@onready var main_menu = $CanvasLayer/main_menu
@onready var color_entry = $CanvasLayer/main_menu/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/color_entry
@onready var username_entry = $CanvasLayer/main_menu/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/username_entry
@onready var players = $players
@onready var effigys = $effigys
@onready var volume_menu = $CanvasLayer/volume_menu
@onready var volume_slider = $CanvasLayer/volume_menu/VBoxContainer/volume_slider

const EFFIGY_SPAWN_TIME = 90.0
var effigy_timer = 20# EFFIGY_SPAWN_TIME
var effigy_counter = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	AudioServer.set_bus_volume_db(0, (volume_slider.value - 50) / 10.0)
	if Input.is_action_pressed("menu"):
		volume_menu.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE 
	else:
		volume_menu.visible = false
		if players.get_child_count() > 0:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED 
	if !multiplayer.is_server():
		return
	effigy_timer -= delta
	if effigy_timer < 0 && multiplayer.get_peers().size() > 0:
		effigy_timer = EFFIGY_SPAWN_TIME
		var effigy = Effigy.instantiate()
		effigy.position = Vector3(randi_range(-60,60),20,randi_range(-60,60))
		effigy.rotate_y(randi_range(0, 360))
		effigy.name = str(effigy_counter)
		effigy_counter += 1
		effigy.set_multiplayer_authority(multiplayer.get_unique_id())
		effigys.add_child(effigy, true)

func _unhandled_input(event):
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()

const PORT = 35555
var enet_peer = ENetMultiplayerPeer.new()

func _on_join_button_pressed():
	main_menu.hide()
	var target = "localhost"
	var port = PORT
	if address_entry.text != "":
		target = address_entry.text.split(":")[0]
		port = address_entry.text.split(":")[1].to_int()
	enet_peer.create_client(target, port)
	multiplayer.multiplayer_peer = enet_peer

func _on_host_button_pressed():
	main_menu.hide()
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	add_player(multiplayer.get_unique_id())

func _on_quit_button_pressed():
	get_tree().quit()
	
func add_player(peer_id):
	print(peer_id)
	var player = Player.instantiate()
	player.name = str(peer_id)
	player.username += str(peer_id)
	players.add_child(player)

func remove_player(peer_id):
	print("removed " + str(peer_id))
	var player = players.get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
