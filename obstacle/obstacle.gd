extends KinematicBody2D

onready var main = $"../..";
onready var tween = $Tween;
onready var collision = $collision;
onready var sprite = $sprite;

var dmg = 10;
var algo = "slow";
var trav_dir = Vector2();
var obstacle_type;

var obstacle_damage = {"wood": 0,
					   "plastic": 0,
					   "glass": 5, 
					   "net": 2, 
					   "barrel": 3,
					   "mine": 4};

var obstacle_algo_type = {"wood": "push",
						  "plastic": "push",
						  "glass": "damage", 
						  "net": "slow", 
						  "barrel": "damage",
						  "mine": "damage"};

var obstacle_scale = {"wood": Vector2(1.5, 1.5),
					  "plastic": Vector2(2, 2),
					  "glass": Vector2(1, 1), 
					  "net": Vector2(1, 1), 
					  "barrel": Vector2(0.6, 0.6),
					  "mine": Vector2(0.6, 0.6)};

var coll_info = {"wood": ["rect", Vector2(12, 5.7), "dummy", Vector2(-1.6, 2.8)],
				 "plastic": ["rect", Vector2(3.7, 5), "dummy", Vector2(-0.6, -0.6)],
				 "glass": ["rect", Vector2(10, 5.54), "dummy", Vector2(0.6, 0.7)], 
				 "net": ["capsule", 8.3, 55.4, Vector2(3.2, 1.4)], 
				 "barrel": ["rect", Vector2(28.5, 40.5), "dummy", Vector2()],
				 "mine": ["circle", 44, "dummy", Vector2(-0.2, -75.6)]};

func init(type):
	if type == "barrel" or type == "plastic": rotation_degrees = rand_range(0, 360);
	obstacle_type = type;
	dmg = obstacle_damage[type];
	algo = obstacle_algo_type[type];
	$sprite.play(type);
	scale = obstacle_scale[type];
	
	var coll; 
	match coll_info[obstacle_type][0]:
		'circle':
			coll = CircleShape2D.new();
			coll.set_radius(coll_info[obstacle_type][1]);
		'capsule':
			coll = CapsuleShape2D.new();
			coll.set_radius(coll_info[obstacle_type][1]);
			coll.set_height(coll_info[obstacle_type][2]);
		'rect':
			coll = RectangleShape2D.new();
			coll.set_extents(coll_info[obstacle_type][1]);
	$collision.set_shape(coll);
	$collision.set_position(coll_info[obstacle_type][3]);

# warning-ignore:unused_argument
func _physics_process(delta):
# warning-ignore:return_value_discarded
	move_and_slide(trav_dir);
	for i in get_slide_count():
		var coll = get_slide_collision(i);
		if coll.get_collider() == main.player:
			call(algo, coll.get_collider());

func push(player):
	trav_dir = (position - player.position).normalized();
	trav_dir *= 50;

func damage(player):
	if obstacle_type == "mine": 
		sprite.play("mine_explode");
	else:
		tween.interpolate_property(self, "modulate", modulate, Color(modulate.r, modulate.g, modulate.b, 0), 1, Tween.TRANS_LINEAR, Tween.EASE_OUT);
		tween.start();
	collision.disabled = true;
	player.damage(dmg, position, "none");
	set_physics_process(false);

func slow(player):
	player.damage(dmg, player.position, "slow");
	set_physics_process(false);
	collision.disabled = true;
	tween.interpolate_property(self, "modulate", modulate, Color(modulate.r, modulate.g, modulate.b, 0), 1, Tween.TRANS_LINEAR, Tween.EASE_OUT);
	tween.start();

# warning-ignore:unused_argument
# warning-ignore:unused_argument
func _on_Tween_tween_completed(object, key):
	queue_free();

func _on_sprite_animation_finished():
	if sprite.get_animation() == "mine_explode": 
		queue_free();
