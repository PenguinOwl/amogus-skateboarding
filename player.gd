extends CharacterBody3D

@onready var camera_3d = $camera_tilt/normal_cam
@onready var animation_player = $camera_tilt/normal_cam/gun_animations
@onready var gun_offset = $camera_tilt/normal_cam/SubViewportContainer/SubViewport/gun_offset
@onready var amogus_model = $amogus_model
@onready var amogus_walk = $amogus_model/WalkAnimation
@onready var view_fx = $view_fx
@onready var ray_cast_3d = $camera_tilt/normal_cam/RayCast3D
@onready var gpu_particles_3d = $camera_tilt/normal_cam/gun_offset/gun/GPUParticles3D
@onready var sub_viewport_container = $camera_tilt/normal_cam/SubViewportContainer
@onready var gun = $camera_tilt/normal_cam/gun_offset/gun
@onready var username_label = $username_label
@onready var ads_animation = $camera_tilt/normal_cam/ads_animation
@onready var shot_particle = $camera_tilt/normal_cam/gun_offset/gun/shot_particle
@onready var bullet_point = $camera_tilt/normal_cam/gun_offset/gun/bullet_point
@onready var bullet_hud = [$camera_tilt/normal_cam/HUD/MarginContainer/HBoxContainer/bullet1, $camera_tilt/normal_cam/HUD/MarginContainer/HBoxContainer/bullet2, $camera_tilt/normal_cam/HUD/MarginContainer/HBoxContainer/bullet3, $camera_tilt/normal_cam/HUD/MarginContainer/HBoxContainer/bullet4, $camera_tilt/normal_cam/HUD/MarginContainer/HBoxContainer/bullet5, $camera_tilt/normal_cam/HUD/MarginContainer/HBoxContainer/bullet6]
@onready var health_label = $camera_tilt/normal_cam/HUD/MarginContainer2/health_label
@onready var hud = $camera_tilt/normal_cam/HUD
@onready var mark_cam = $"../../CanvasLayer3/SubViewportContainer2/SubViewport/mark_cam"
@onready var mark_cam_container = $"../../CanvasLayer3/SubViewportContainer2"
@onready var chungus_shader = $"../../CanvasLayer2/ColorRect"
@onready var mark = $mark
@onready var chungus_check = $camera_tilt/normal_cam/chungus_check
@onready var chungus_ui = $camera_tilt/normal_cam/HUD/chungus_ui
@onready var chungus_progress = $camera_tilt/normal_cam/HUD/chungus_ui/VBoxContainer/chungus_progress
@onready var audio_players = $audio_players
@onready var footstep = $audio_players/Footstep
@onready var laugh = $audio_players/Laugh
@onready var speed = $audio_players/Speed

const Bullet = preload("res://bullet.tscn")
const Bullet_full = preload("res://full.png")
const Bullet_empty = preload("res://empty.png")
const sound_fire = preload("res://sounds/fire.ogg")
const sound_footstep = preload("res://sounds/footstep.ogg")
const sound_reload = preload("res://sounds/reload.ogg")
const sound_crit = preload("res://sounds/crit.ogg")

const AUDIO_CHANNELS = 15
const SPEED = 10.0
const JUMP_VELOCITY = 18
const AIR_DRAG = 1.5
const GROUND_DRAG = 10.0
const AIR_ACCEL = 10
const GROUND_ACCEL = 150
const FIRE_RATE = 0.7
const MAX_HEALTH = 5
@export var color = Color.RED
@export var username = "Player "
var cached_color = null
var cached_username = null
var bullets = 6
var reload_timer = 0.0
var health = MAX_HEALTH
var chungus_mode = 0.0
var cap_progress = 0.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 3.7
var ground_buffer = 0.0
var fire_timer = 0.0
var fire_buffer = 0.0
var dash_timer = 0.0
var chungus_timer = 0.0
var dash_cooldown = 0.0
var reload_buffer = 0.0
var current_player = 0
var footstep_timer = 0.0
var players = []

func get_chungus():
	var collider = chungus_check.get_collider()
	if collider && collider.name == "capture_zone":
		return collider

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())
	
func _ready():
	for _i in range(AUDIO_CHANNELS):
		var player : AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		players.append(player)
		audio_players.add_child(player)
	if not is_multiplayer_authority():
		amogus_model.render_model = true
		camera_3d.remove_child(sub_viewport_container)
		gun.set_visual_layers(1)
		hud.visible = false
		camera_3d.current = false
		return
	username_label.visible = false
	mark.visible = false
	var username_box = get_parent().get_parent().username_entry
	var color_box = get_parent().get_parent().color_entry
	if username_box && color_box:
		if username_box.text.strip_edges() != "":
			username = username_box.text.strip_edges()
		else:
			username += str(name)
		color = color_box.color
		print(color)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED 
	camera_3d.current = true

func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.005)
		camera_3d.rotate_x(-event.relative.y  *  0.005)
		camera_3d.rotation.x = clamp(camera_3d.rotation.x,-PI/2, PI/2)

func _process(delta):
	get_chungus()
	if cached_color != color:
		amogus_model.set_color(color)
		cached_color = color
	if cached_username != username:
		username_label.text = username
		cached_username = username
	if not is_multiplayer_authority(): return
	var target_chungus_mode = 1 if chungus_timer > 0 else 0
	chungus_mode = move_toward(chungus_mode, target_chungus_mode, delta * 0.7)
	mark_cam_container.modulate.a = chungus_mode
	chungus_shader.material.set_shader_parameter("strength", chungus_mode)
	health_label.text = str(health) + " HP"
	gun_offset.global_transform = camera_3d.global_transform
	mark_cam.global_transform = camera_3d.global_transform
	amogus_model.render_model = false
	fire_timer -= delta
	fire_buffer -= delta
	reload_timer -= delta
	reload_buffer -= delta
	chungus_timer -= delta
	if Input.is_action_just_pressed("fire"):
		fire_buffer = 0.1
	if Input.is_action_just_pressed("reload"):
		reload_buffer = 0.1
	if fire_buffer > 0 && reload_timer < 0 && fire_timer < 0:
		if bullets <= 0:
			gun_reload()
			return
		bullets -= 1
		bullet_hud[bullets].texture = Bullet_empty
		fire_timer = 0.2
		fire_buffer = 0
		animation_player.play("shoot", 0.05)
		var crit_chance = 1.0 if chungus_mode else 0.01
		var crit = randf() < crit_chance
		gun_fire.rpc(bullet_point.global_transform, ray_cast_3d.get_collision_point(), crit)
		var collider = ray_cast_3d.get_collider()
		if collider is CharacterBody3D && collider.has_method("gun_hit"):
			collider.gun_hit.rpc_id(str(collider.name).to_int(), 5 if crit else 1)
	if reload_buffer > 0 && reload_timer < 0 && fire_timer < 0:
		gun_reload()

@rpc("call_local") func gun_fire(transform, target, crit):
	gpu_particles_3d.restart()
	var bullet = Bullet.instantiate()
	bullet.global_transform = transform
	bullet.velocity = transform.basis.x * -80
	bullet.max_distance = (transform.origin - target).length()
	bullet.is_crit = crit
	play_sound(sound_fire, -13)
	if not is_multiplayer_authority():
		bullet.layers = 1
	get_parent().add_child(bullet)

@rpc("any_peer") func gun_hit(damage):
	health -= damage
	if health <= 0:
		chungus_timer = 0.0
		health = MAX_HEALTH
		position = Vector3(randi_range(-70,70),20,randi_range(-70,70))

func gun_reload():
	play_sound(sound_reload, 0)
	animation_player.play("reload")
	bullets = 6
	reload_timer = 0.65
	for bullet_icon in bullet_hud:
		bullet_icon.texture = Bullet_full

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	var acceleration = Vector3(0, 0, 0)
	
	if position.y < -20:
		gun_hit(1)
	
	ground_buffer -= delta
	if is_on_floor():
		ground_buffer = 0.1
	
	# Add the gravity.
	if not is_on_floor():
		acceleration.y -= gravity

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and ground_buffer > 0:
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var drag_factor = GROUND_DRAG if is_on_floor() else AIR_DRAG
	var accel_factor = GROUND_ACCEL if is_on_floor() else AIR_ACCEL
	if dash_timer > 0:
		drag_factor *= 0.4
	if direction.dot(velocity) < SPEED + chungus_mode * SPEED:
		acceleration += direction * accel_factor
	acceleration += -1 * drag_factor * velocity
	
	var ads = Input.is_action_pressed("ads")
	
	dash_timer -= delta
	dash_cooldown -= delta
	footstep_timer -= delta
	if Input.is_action_just_pressed("dash") && is_on_floor() && dash_cooldown < 0:
		velocity += direction * SPEED * 1.75
		dash_timer = 0.3
		dash_cooldown = 0.85
		if input_dir.x > 0:
			view_fx.play("dash_left")
		if input_dir.x < 0:
			view_fx.play("dash_right")
	
	if reload_timer < 0:
		if direction != Vector3.ZERO and is_on_floor():
			animation_player.play("ads" if ads else "move")
			if !footstep.playing:
				footstep.play(0.0)
			amogus_walk.play("walk")
			view_fx.play("walk")
			amogus_walk.speed_scale = velocity.length() / SPEED * 2
		else:
			footstep.playing = false
			animation_player.play("ads" if ads else "idle")
			amogus_walk.play("idle")
			view_fx.play("idle")
	
	if ads:
		ads_animation.play("ads")
	else:
		ads_animation.play("idle")
		
	if get_chungus():
		var target_chungus = get_chungus().get_parent()
		chungus_ui.visible = true
		if Input.is_action_pressed("use"):
			chungus_progress.visible = true
			var half_mark = target_chungus.cap_time / 2.0
			if target_chungus.half_capped && cap_progress < half_mark:
				cap_progress = half_mark
			cap_progress += delta
			if !target_chungus.interacted:
				target_chungus.interact.rpc()
			chungus_progress.value = cap_progress / target_chungus.cap_time * 100
			if !target_chungus.half_capped && cap_progress > half_mark:
				target_chungus.set_half.rpc()
		else:
			cap_progress = 0.0
			chungus_progress.visible = target_chungus.half_capped
			chungus_progress.value = 50 if target_chungus.half_capped else 0
		if cap_progress > target_chungus.cap_time:
			chungus_timer = 20.0
			speed.play()
			laugh.play(0.0)
			cap_progress = 0.0
			target_chungus.remove.rpc()
	else:
		chungus_ui.visible = false
		cap_progress = 0.0
	
	if chungus_timer < 0.0:
		speed.stop()
	
	velocity += acceleration * delta

	move_and_slide()


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		animation_player.play("idle")
	if anim_name == "reload":
		animation_player.play("idle",0)

@rpc("call_local") func play_sound(sound, db = 0.0):
	var player : AudioStreamPlayer3D = players[current_player]
	current_player = (current_player + 1) % AUDIO_CHANNELS
	player.stream = sound
	player.volume_db = db
	player.play(0.0)
