extends KinematicBody2D

signal tutorial_complete

onready var player = $"../../player";
onready var sprite = $sprite;
onready var collision = $collision;
onready var anim_player = $anim_player;
onready var melee = $melee_weapon;
onready var melee_coll = $melee_weapon/collision;
onready var timer = $cooldown_timer;
onready var cc_timer = $cc_timer;
onready var dash_timer = $dash_timer;

var damage_dict := {"orca": 3,
					"lamprey": 1};

var speed_dict := {"orca": 200,
				   "lamprey": 300};

var arange_dict := {"orca": 700,
					"lamprey": 500};

var erange_dict := {"orca": 300,
					"lamprey": 200};

var scale_dict := {"orca": Vector2(2, 2),
				   "lamprey": Vector2(1, 1)};

var health_dict := {"orca": 4,
					"lamprey": 1};

var cd_dict := {"orca": 3,
				"lamprey": 2};

var melee_pos_dict := {"orca": Vector2(57.6, 4.9),
					   "lamprey": Vector2(49.7, -0.5)};

var melee_coll_info := {"orca": 14,
						"lamprey": 10.5};

var coll_info := {"orca": ["rect", Vector2(64.9, 11.4), "dummy", Vector2(2.7, 3.2)],
				  "lamprey": ["rect", Vector2(60.1, 7.8), "dummy", Vector2(0.1, -3.8)]};

var status_dict := {"orca": "none",
					"lamprey": "slow"}

var damage;
var status;
var speed = 200;
var arange := 0;
var erange := 0;
var enemy_type;
var health = 20;
var STATE = 'IDLE';
var STATE_LOCK := true;
var knockback_dir := Vector2();
var cd;
var dash_dir := Vector2();

func _physics_process(delta):
	if STATE_LOCK:
		STATE = change_state();
		STATE_LOCK = false;
	match STATE:
		"DEAD":
			timer.stop();
			sprite.play(enemy_type + "_death");
			anim_player.play("death");
			collision.set_deferred("disabled", true);
			set_physics_process(false);
		
		"MOVE":
			timer.paused = true;
			sprite.play(enemy_type + "_move");
			var direction_of_trav = (player.position - global_position).normalized();
# warning-ignore:return_value_discarded
			move_and_collide(direction_of_trav*speed*delta);
			STATE_LOCK = true;
			
		"ATTACK":
			timer.paused = false;
			sprite.play(enemy_type + "_idle");
			STATE_LOCK = true;
		
		"ATTACK_2":
			if health <= 0:
				STATE_LOCK = true;
# warning-ignore:return_value_discarded
			position = position.linear_interpolate(dash_dir, delta*10);
		
		"IDLE": 
			timer.paused = true;
			sprite.play(enemy_type + "_idle");
			STATE_LOCK = true;
			
		"CC":
# warning-ignore:return_value_discarded
			move_and_collide(knockback_dir*500*delta);
			
	if position.x - player.position.x > 0:
		sprite.flip_h = true;
		collision.set_position(Vector2(-coll_info[enemy_type][3].x, coll_info[enemy_type][3].y));
		melee.set_position(Vector2(-melee_pos_dict[enemy_type].x, melee_pos_dict[enemy_type].y));
	else:
		sprite.flip_h = false;
		collision.set_position(coll_info[enemy_type][3]);
		melee.set_position(melee_pos_dict[enemy_type]);

func init(type, pos):
	enemy_type = type;
	position = pos;
	damage = damage_dict[enemy_type];
	erange = erange_dict[enemy_type];
	health = health_dict[enemy_type];
	speed = speed_dict[enemy_type];
	cd = cd_dict[enemy_type];
	scale = scale_dict[enemy_type];
	arange = arange_dict[enemy_type];
	
	#setting collision boxes
	var coll; 
	match coll_info[enemy_type][0]:
		'circle':
			coll = CircleShape2D.new();
			coll.set_radius(coll_info[enemy_type][1]);
		'capsule':
			coll = CapsuleShape2D.new();
			coll.set_radius(coll_info[enemy_type][1]);
			coll.set_height(coll_info[enemy_type][2]);
		'rect':
			coll = RectangleShape2D.new();
			coll.set_extents(coll_info[enemy_type][1]);
	$collision.set_shape(coll);
	$collision.set_position(coll_info[enemy_type][3]);
	
	set_physics_process(true);

# warning-ignore:function_conflicts_variable
func damage(pos): 
	anim_player.play("damage");
	health -= 1;
	if health <= 0:
		STATE_LOCK = false;
		STATE = "DEAD";
	elif pos != Vector2():
		knockback_dir = (position - pos).normalized();
		cc_timer.start();
		STATE_LOCK = false;
		STATE = "CC";

func _on_cooldown_timer_timeout():
	STATE_LOCK = false;
	STATE = 'ATTACK_2';
	dash_dir = player.position;
	melee_coll.disabled = false;
	timer.start(cd);
	dash_timer.start();

func _on_cc_timer_timeout():
	STATE_LOCK = true;
	timer.start(cd);

func change_state():
	if global_position.distance_to(player.position) > arange:
		return 'IDLE';
	elif global_position.distance_to(player.position) > erange:
		return 'MOVE';
	else:
		return 'ATTACK';

func _on_sprite_animation_finished():
	if sprite.get_animation() == (enemy_type + "_death"):
		queue_free();
		if is_in_group("tutorial_node"): emit_signal("tutorial_complete");

func _on_dash_timer_timeout():
	STATE_LOCK = true;
	melee_coll.disabled = true;

func _on_melee_weapon_body_entered(body):
	if body.is_in_group("player"):
		body.damage(damage, position, status);
