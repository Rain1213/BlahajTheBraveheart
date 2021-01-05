extends KinematicBody2D

var bullet = preload("res://bullet/bullet.tscn");

onready var player = $"../../player";
onready var sprite = $sprite;
onready var collision = $collision;
onready var anim_player = $anim_player;
onready var bullet_container = $bullet_container;
onready var muzzle = $muzzle;
onready var timer = $cooldown_timer;
onready var cc_timer = $cc_timer;


var speed_dict := {"harpoon": 50,
				   "ultrasonic": 25,
				   "tranq": 25};

var arange_dict := {"harpoon": 900,
					"ultrasonic": 500,
					"tranq": 500};

var erange_dict := {"harpoon": 800,
					"ultrasonic": 400,
					"tranq": 400};

var scale_dict := {"harpoon": Vector2(1, 1),
				   "ultrasonic": Vector2(1, 1),
				   "tranq": Vector2(1, 1)};

var health_dict := {"harpoon": 1,
					"ultrasonic": 1,
					"tranq": 1};

var cd_dict := {"harpoon": 4,
				"ultrasonic": 3,
				"tranq": 3};

var muzzle_pos_dict := {"harpoon": Vector2(55.7, -28.8),
						"ultrasonic": Vector2(72.4, -32),
						"tranq": Vector2(58.7, -32.2)};

var coll_info := {"harpoon": ["capsule", 10, 104.5, Vector2(-3.4, -7.4)],
				  "ultrasonic": ["capsule", 10, 104.5, Vector2(7.8, -10.9)],
				  "tranq": ["capsule", 10, 104.5, Vector2(-8, -7.7)]};

var speed = 200;
var arange := 0;
var erange := 0;
var enemy_type;
var health = 20;
var STATE = 'IDLE';
var STATE_LOCK := true;
var knockback_dir := Vector2();
var cd;

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
			
		"SHOOT":
			timer.paused = false;
			sprite.play(enemy_type + "_idle");
			STATE_LOCK = true;
		
		"SHOOT_2":
			if health <= 0:
				STATE_LOCK = true;
		
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
		muzzle.set_position(Vector2(-muzzle_pos_dict[enemy_type].x, muzzle_pos_dict[enemy_type].y));
	else:
		sprite.flip_h = false;
		collision.set_position(coll_info[enemy_type][3]);
		muzzle.set_position(muzzle_pos_dict[enemy_type]);

func init(type, pos):
	enemy_type = type;
	position = pos;
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
	STATE_LOCK = true;
	match enemy_type:
		"harpoon":
			single_shoot();
		"tranq":
			single_shoot();
		"ultrasonic":
			burst_shoot();
	timer.start(cd);

func _on_cc_timer_timeout():
	STATE_LOCK = true;
	timer.start(cd);

func change_state():
	if global_position.distance_to(player.position) > arange:
		return 'IDLE';
	elif global_position.distance_to(player.position) > erange:
		return 'MOVE';
	else:
		return 'SHOOT';

func single_shoot():
	var b = bullet.instance();
	b.scale = scale;
	bullet_container.add_child(b);
# warning-ignore:incompatible_ternary
	b.start(sprite.flip_h, muzzle.get_angle_to(player.position), muzzle.global_position, enemy_type);

func burst_shoot():
	for i in range(4):
		var b = bullet.instance();
		bullet_container.add_child(b);
		b.start(sprite.flip_h, muzzle.get_angle_to(player.position) + i*.1, muzzle.global_position, enemy_type);
		yield(get_tree().create_timer(0.05), "timeout");

func _on_sprite_animation_finished():
	if sprite.get_animation() == (enemy_type + "_death"):
		queue_free();
