extends Node2D

var shoot_enemy = preload("res://enemy/shoot_enemy.tscn");
var dash_enemy = preload("res://enemy/dash_enemy.tscn");
var particle = preload("res://particle/particle.tscn");
var obstacle = preload("res://obstacle/obstacle.tscn");

onready var environment = $environment;
onready var HUD = $HUD;
onready var player = $player;
onready var music = $music;
onready var camera = $camera;
onready var enemy_spawn_timer = $enemy_spawner;
onready var obstacle_spawn_timer = $obstacle_spawner;
onready var particle_spawn_timer = $particle_spawner;
onready var enemy_container = $enemy_container;
onready var obstacle_container = $obstacle_container;
onready var particle_container = $particle_container;
onready var tut_obs = $tutorial_nodes/obstacle;
onready var tut_enemy = $tutorial_nodes/enemy;
onready var bk_map = $bk_map;
onready var bk_anim_player = $bk_map/AnimationPlayer;

var enemy_num;
var enemy_spawn_threshold_x = 500;
var obstacle_spawn_threshold_x = 500;
var particle_spawn_threshold_x = 500;
var base_coords := Vector2();
var game_status := false;

func _ready():
	if global.skip_tut: 
		global.skip_tut = false;
		start_real_game();
	else:
		tut_obs.init("barrel");
		tut_enemy.init("lamprey", tut_enemy.position);
		tut_obs.dmg = 1;
	for i in range(24):
		bk_map.tile_set.tile_set_texture(i, load("res://art/main/background_s" + String(global.stage) + ".png"));
	enemy_num = global.enemy_num[global.stage];
	spawn_background();

# warning-ignore:unused_argument
func _process(delta):
	music.position = player.position;
	if music.position.x >= bk_map.map_to_world(base_coords).x - get_viewport_rect().size.x: spawn_background();

func change_stage():
	if global.stage == global.final_stage:
		game_complete();
		return;
	enemy_spawn_timer.stop();
	obstacle_spawn_timer.stop();
	particle_spawn_timer.stop();
	global.stage += 1;
	HUD.flash_notifier(global.stage);
	enemy_num = global.enemy_num[global.stage];
	bk_anim_player.play("fade_out");

func spawn_enemy():
	var enemy_type = global.enemy_list[global.stage][randi() % global.enemy_list[global.stage].size()];
	var e;
	if global.stage == 4:
		e = shoot_enemy.instance();
	else:
		e = dash_enemy.instance();
	e.init(enemy_type, set_pos(rand_range(0, 600)));
	enemy_container.add_child(e);

func spawn_obstacle():
	var e = obstacle.instance();
	var obs_type = global.obstacle_list[global.stage][randi() % global.obstacle_list[global.stage].size()];
	if global.obstacle_pos_y[obs_type] is String:
		e.position = set_pos(rand_range(0, 600));
	else:
		e.position = set_pos(global.obstacle_pos_y[obs_type]);
	e.init(obs_type);
	obstacle_container.add_child(e);

func spawn_particle():
	var e = particle.instance();
	e.position = set_pos(rand_range(0, 600));
	particle_container.add_child(e);

func tutorial_complete():
	player.set_process_input(false);
	player.set_physics_process(false);
	HUD.tutorial_complete();

func start_real_game():
	HUD.flash_notifier(global.stage);
	player.set_process_input(true);
	player.set_physics_process(true);
	player.straighten();
	player.position = get_viewport_rect().size/2;
	$tutorial_nodes.queue_free();
	player.health = player.health_dict[player.character];
	HUD.update_hp_bar(player.health);
	enemy_spawn_timer.start();
	obstacle_spawn_timer.start();
	particle_spawn_timer.start();

func _on_enemy_spawner_timeout():
	if player.position.x >= enemy_spawn_threshold_x and enemy_num > 0:
		enemy_num -= 1;
		spawn_enemy();
		enemy_spawn_threshold_x = camera.position.x + 300;
	elif enemy_num == 0:
		change_stage();

func _on_obstacle_spawner_timeout():
	if player.position.x >= obstacle_spawn_threshold_x:
		spawn_obstacle();
		obstacle_spawn_threshold_x = camera.position.x + 300;

func _on_particle_spawner_timeout():
	if player.position.x >= particle_spawn_threshold_x:
		spawn_particle();
		particle_spawn_threshold_x = camera.position.x + 1000;

func set_pos(pos_y):
	return Vector2(camera.position.x + get_viewport_rect().size.x, pos_y);

func game_complete():
	game_status = true;
	player.set_process_input(false);
	camera.get_node("Tween").interpolate_property(Engine, "time_scale", 1, 0.1, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT);
	camera.get_node("Tween").interpolate_property(camera, "zoom", Vector2(1, 1), Vector2(0.5, 0.5), 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT);
	camera.get_node("Tween").start();

func game_over():
	camera.follow_player_y = true;
	camera.get_node("Tween").interpolate_property(Engine, "time_scale", 1, 0.1, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT);
	camera.get_node("Tween").interpolate_property(camera, "zoom", Vector2(1, 1), Vector2(0.5, 0.5), 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT);
	camera.get_node("Tween").start();

func spawn_background():
	for h in range(2):
		var x = 0;
		for i in range(3):
			for j in range(8):
				bk_map.set_cell(base_coords.x + j + h*8, base_coords.y + i, x);
				x += 1;
	base_coords += Vector2(16, 0);

# warning-ignore:unused_argument
# warning-ignore:unused_argument
func _on_Tween_tween_completed(object, key): 
	if game_status:
		HUD.game_complete();
	else: 
		HUD.player_died();

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "fade_out":
		for i in range(24):
			bk_map.tile_set.tile_set_texture(i, load("res://art/main/background_s" + String(global.stage) + ".png"));
		HUD.stage_changed(global.stage);
		enemy_spawn_timer.start();
		obstacle_spawn_timer.start();
		particle_spawn_timer.start();
		bk_anim_player.play("fade_in");
