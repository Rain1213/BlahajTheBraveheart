extends Area2D

onready var sprite = $sprite;
onready var collision = $collision;
onready var anim_player = $AnimationPlayer;

var speed_dict := {"harpoon": 200,
				   "ultrasonic": 150,
				   "tranq": 300};

var damage_dict := {"harpoon": 6,
					"ultrasonic": 2,
					"tranq": 2};

var coll_info := {"harpoon": ["rect", Vector2(34.6, 1.4), "dummy", Vector2(-1, -2.6)],
				  "tranq": ["rect", Vector2(19.8, 2.3), "dummy", Vector2(-1, -0.24)],
				  "ultrasonic": ["capsule", 2.9, 44.5, Vector2(4.1, -0.4)]};

var algo_dict := {"harpoon": "curve",
				  "ultrasonic": "straight",
				  "tranq": "straight"};

var status_dict := {"harpoon": "none",
					"ultrasonic": "none",
					"tranq": "slow"};

var vel = Vector2();
var speed = 600;
var rot = 1;
var algo;
var status;
var bullet_type;
var damage;
var extents;
var screensize;

func start(flip_h, dir, pos, type):
	vel = Vector2(speed, 0);
	if algo_dict[type] == "straight":
		vel = vel.rotated(dir);
		rotation = dir;
	else:
		rot = -rot;
		vel = -vel;
		sprite.flip_h = flip_h;
	position = pos;
	speed = speed_dict[type];
	bullet_type = type;
	algo = algo_dict[type];
	damage = damage_dict[type];
	extents = load("res://art/bullet/" + bullet_type + "/fly_1.png").get_size()/2;
	sprite.play(bullet_type + "_fly");
	var coll;
	match coll_info[bullet_type][0]:
		"capsule":
			coll = CapsuleShape2D.new();
			coll.radius = coll_info[bullet_type][1];
			coll.height = coll_info[bullet_type][2];
		"circle":
			coll = CircleShape2D.new();
			coll.radius = coll_info[bullet_type][1];
		"rect":
			coll = RectangleShape2D.new();
			coll.extents = coll_info[bullet_type][1];
	collision.shape = coll;
	collision.position = coll_info[bullet_type][3];
	screensize = get_viewport_rect().size;
	set_physics_process(true);

func _physics_process(delta):
	call(algo, delta);
	clamp_bullet();

func straight(delta):
	position += vel * delta;

func curve(delta):
	position += vel * delta;
	vel = vel.rotated(deg2rad(rot));
	rotation_degrees += rot;

func clamp_bullet():
	if position.x <= -extents.x/2:
		queue_free();
	elif position.x <= $"../../../../player".position.x - 1500:
		queue_free(); 
	elif position.y >= screensize.y + extents.y:
		queue_free(); 
	elif position.y <= -extents.y:
		queue_free(); 

func _on_bullet_body_entered(body):
	if body.is_in_group("player"):
		collision.set_deferred("disabled", true);
		queue_free();
		vel = Vector2(0, 0);
		body.damage(damage_dict[bullet_type], $"../..".position, "none");
	elif body.is_in_group("obstacle"):
		queue_free();
		collision.set_deferred("disabled", true);
		vel = Vector2(0, 0);

func _on_sprite_animation_finished():
	if sprite.get_animation() == "ultrasonic":
		anim_player.play("collide");

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "collide":
		queue_free();
