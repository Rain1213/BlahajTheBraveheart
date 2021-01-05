extends KinematicBody2D

signal update_hp_bar(health);
signal player_dead;
signal update_HUD_info(health, base_exp);

onready var dash_timer = $dash_timer;
onready var sprite = $sprite;
onready var collision = $collision;
onready var main = $"..";
onready var anim_player = $AnimationPlayer;
onready var knockback_timer = $knockback_timer;
onready var dash_cooldown = $dash_cooldown;
onready var melee_coll = $melee_weapon/collision;
onready var melee_weapon = $melee_weapon;

var health_dict = {"male": 20,
				   "female": 35};

var damage_dict = {"male": 2,
				   "female": 1};

var speed_dict = {"male": 300,
				  "female": 200};

var coll_info = {"male": Vector2(4.1, 10.4),
				 "female": Vector2(3.5, 2.9)};

var melee_coll_info = {"male": Vector2(62.2, 9),
					   "female": Vector2(61.8, 2.3)};

var dash_cd_dict = {"male": 3,
					"female": 2};

var melee_pos_x;
var coll_pos_x;
var character;
var health;
var base_exp = 100;
var speed;
var min_speed;
var max_speed;
var damage;
var rot_speed;
var velocity = Vector2();
var STATE = "MOVE";
var dash_dir = Vector2();
var moving := false;
var extents;
var screensize; 
var knockback_dir;
var can_dash := true;

func _ready():
	character = global.character;
	health = health_dict[character];
	damage = damage_dict[character];
	min_speed = speed_dict[character];
	dash_cooldown.set_wait_time(dash_cd_dict[character]);
	max_speed = min_speed + 150;
	speed = min_speed;
	rot_speed = 150 + (min_speed - 200)/4;
	melee_weapon.position = melee_coll_info[character];
	collision.position = coll_info[character];
	melee_pos_x = melee_weapon.position.x;
	coll_pos_x = collision.position.x;
	extents = load("res://art/player/" + character +  "/move/1.png").get_size() / 2;
	emit_signal("update_HUD_info", health, base_exp);
	screensize = get_viewport_rect().size;

func _input(event):
	if event.is_action_pressed("player_attack") and can_dash:
		STATE = "ATTACK";
		dash_timer.start();
		dash_dir = Vector2(-1 if sprite.flip_h else 1, 0).rotated(rotation);
		sprite.speed_scale = 10;
		melee_coll.disabled = false;
		collision.disabled = true;
		can_dash = false;

# warning-ignore:unused_argument
func _physics_process(delta):
	match STATE:
		"MOVE":
			velocity = Vector2();
			moving = false;
			if rotation_degrees >= 90 or rotation_degrees <= -90:
				sprite.flip_h = not sprite.flip_h;
				rotation_degrees = rotation_degrees - 180;
			if Input.is_action_pressed("player_forward"):
				velocity = Vector2(-1 if sprite.flip_h else 1, 0).rotated(rotation);
				moving = true;
				if Input.is_action_pressed("player_up"):
					rotation_degrees -= rot_speed * delta;
				elif Input.is_action_pressed("player_down"):
					rotation_degrees += rot_speed * delta;
				sprite.play(character + "_move");
			else:
				sprite.play(character + "_idle");
			velocity = clamp_player(velocity);
			speed = speed + 3 if velocity != Vector2() else min_speed;
			speed = clamp(speed, min_speed, max_speed);
		# warning-ignore:return_value_discarded
			move_and_slide(velocity*speed);
		"ATTACK":
# warning-ignore:return_value_discarded
			dash_dir = clamp_player(dash_dir);
			move_and_slide(dash_dir*speed*10);
		"KNOCKBACK":
			knockback_dir = clamp_player(knockback_dir);
# warning-ignore:return_value_discarded
			move_and_slide(knockback_dir*speed*10);
		"DEAD":
			health = 0;
			main.environment.set_environment(load("res://death_env.tres"));
# warning-ignore:return_value_discarded
			set_physics_process(false);
			sprite.play(character + "_death");
	if sprite.flip_h:
		melee_weapon.position.x = -melee_pos_x;
		collision.position.x = -coll_pos_x;
	else:
		melee_weapon.position.x = melee_pos_x;
		collision.position.x = coll_pos_x;

func clamp_player(dir):
	if position.x <= extents.x and (dir.x <= 0):
		dir.x = 0;
	if position.y >= screensize.y - extents.y and (dir.y >= 0):
		dir.y = 0;
	if position.y <= extents.y and (dir.y <= 0):
		dir.y = 0;
	return dir;

# warning-ignore:function_conflicts_variable
func damage(amount, pos, status):
	health -= amount;
	if health <= 0:
		STATE = "DEAD";
		emit_signal("player_dead");
		anim_player.play("death");
	else:
		knockback_dir = (position - pos).normalized();
		if knockback_dir == Vector2(): return;
		knockback_timer.start(0.1);
		STATE = "KNOCKBACK";
		status(status);
		anim_player.play("damage");
	emit_signal("update_hp_bar", health);

func _on_dash_timer_timeout():
	STATE = "MOVE";
	sprite.speed_scale = 1;
	melee_coll.disabled = true;
	collision.disabled = false;
	dash_cooldown.start();

func _on_knockback_timer_timeout():
	STATE = "MOVE";

func status(type):
	match type:
		"slow":
			min_speed -= 200;
			max_speed -= 200;
			yield(get_tree().create_timer(2), "timeout");
			min_speed += 200;
			max_speed += 200;

func straighten():
	sprite.flip_h = false;
	rotation_degrees = 0;

func _on_melee_weapon_body_entered(body):
	if body.is_in_group("enemy"):
		body.damage(position);

func _on_dash_cooldown_timeout():
	can_dash = true;
