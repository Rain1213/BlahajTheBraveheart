extends CanvasLayer

signal reset_items;

onready var main = $"..";
onready var player_hp_bar = $player_hp_bar;
onready var water_rect = $water;
onready var time_score = $time_score;
onready var character_type = $character_type;
onready var mute_button = $mute_button;
onready var stage_notifier = $stage_notifier;
onready var exp_bar = $exp_node_container/exp_amt;
onready var exp_level = $exp_node_container/exp_level;
onready var pause_panel = $pause_panel;
onready var pause_rect = $pause_rect;
onready var end_game_panel = $end_game_panel;
onready var verdict = $end_game_panel/container/verdict;
onready var progress = $end_game_panel/container/progress;
onready var score = $end_game_panel/container/score;
onready var anim_player = $AnimationPlayer;
onready var trans = $transition;

var start_time;
var current_time;
var mute_state = false;
var once = true;

func _ready():
	start_time = OS.get_unix_time();
	stage_changed(1);

func _input(event):
	if event.is_action_pressed("pause_toggle"):
		global.paused = not global.paused;
		get_tree().set_pause(global.paused);
		pause_rect.visible = global.paused;
		pause_panel.visible = global.paused;
		set_physics_process(not global.paused);
		if global.paused:
			current_time = OS.get_unix_time();
		else:
			start_time += (OS.get_unix_time() - current_time);

# warning-ignore:unused_argument
func _physics_process(delta):
	current_time = OS.get_unix_time();
	set_time_score();

func update_hp_bar(player_current_hp):
	player_hp_bar.value = player_current_hp;

func _on_player_update_HUD_info(health, base_exp):
	$player_hp_bar.max_value = health;
	$player_hp_bar.value = health;
	$character_type.texture = load("res://art/HUD/" + global.character + "_icon.png");
	$exp_node_container/exp_amt.max_value = base_exp;
	$exp_node_container/exp_level.text = "Level:" + String(global.player_level);

func set_time_score():
	if (current_time-start_time)%60 < 10:
		if (current_time-start_time)/60 < 10:
			time_score.text = "0" + String((current_time-start_time)/60) + ":" + "0" + String((current_time-start_time)%60);
		else:
			time_score.text = String((current_time-start_time)/60) + ":" + "0" + String((current_time-start_time)%60);
	else:
		if (current_time-start_time)/60 < 10:
			time_score.text = "0" + String((current_time-start_time)/60) + ":" + String((current_time-start_time)%60);
		else:
			time_score.text = String((current_time-start_time)/60) + ":" + String((current_time-start_time)%60);

func _on_mute_button_pressed():
	mute_button.texture_normal = load("res://art/HUD/unmuted_icon.png") if mute_state else load("res://art/HUD/muted_icon.png");
	mute_state = not mute_state;
	main.music.stream_paused = mute_state;

func add_exp(amount):
	exp_bar.value += amount;

# warning-ignore:unused_argument
func _on_exp_amt_value_changed(value):
	if exp_bar.value >= exp_bar.max_value:
		exp_bar.value = 0;
		global.player_level += 1;
		exp_level.text = "Level:" + String(global.player_level);

func _on_unpause_button_pressed():
	global.paused = not global.paused;
	get_tree().set_pause(global.paused);
	pause_rect.visible = global.paused;
	pause_panel.visible = global.paused;
	start_time += (OS.get_unix_time() - current_time);
	set_physics_process(true);

func _on_exit_button_pressed():
	global.paused = not global.paused;
	get_tree().set_pause(global.paused);
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://main_menu/main_menu.tscn");

func _on_pause_button_pressed():
	global.paused = not global.paused;
	get_tree().set_pause(global.paused);
	pause_rect.visible = global.paused;
	pause_panel.visible = global.paused;
	set_physics_process(not global.paused);
	if global.paused:
		current_time = OS.get_unix_time();
	else:
		start_time += (OS.get_unix_time() - current_time);

func stage_changed(stage):
	water_rect.get_node("Tween").interpolate_property(water_rect.material, 
						"shader_param/water_color", 
						water_rect.material.get_shader_param("water_color"), global.stage_water_color[stage], 3, 
						Tween.TRANS_LINEAR, Tween.EASE_OUT);
	water_rect.get_node("Tween").interpolate_property(water_rect.material, 
						"shader_param/darkness", 
						water_rect.material.get_shader_param("darkness"), global.stage_water_darkness[stage], 3, 
						Tween.TRANS_LINEAR, Tween.EASE_OUT);
	water_rect.get_node("Tween").start();

func flash_notifier(stage):
	var stage_notifier_text = {1: "There will be hoomans in our way",
							   2: "The humans draw closer..",
							   3: "Is that..land?",
							   4: "Shimatta! The hoomans are here!"};
	stage_notifier.text = stage_notifier_text[stage];
	stage_notifier.get_node("Tween").interpolate_property(stage_notifier, "modulate", Color(0, 0, 0, 0), Color(0, 0, 0, 1), 2, Tween.TRANS_LINEAR, Tween.EASE_OUT);
	stage_notifier.get_node("Tween").start();

func player_died():
	set_physics_process(false);
	end_game_panel.show();
	verdict.text = "You died! Blahaj was a plushie till the very end.";
	progress.text = "STAGE: " + String(global.stage);
	score.text = "SCORE: " + time_score.text;

func game_complete():
	set_physics_process(false);
	$game_over_trans.show();
	$game_over_trans/VBoxContainer/score.text = "SCORE: " + time_score.text;
	anim_player.play("fade_in_endscreen");

func _on_replay_pressed():
	get_tree().set_pause(false);
	global.skip_tut = true;
	Engine.time_scale = 1;
# warning-ignore:return_value_discarded
	global.stage = 1;
	get_tree().reload_current_scene();

func _on_quit_pressed():
	get_tree().set_pause(false);
	Engine.time_scale = 1;
	global.stage = 1;
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://main_menu/main_menu.tscn");

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "fade_in_transition":
		emit_signal("reset_items");
		yield(get_tree().create_timer(1), "timeout");
		anim_player.play("fade_out_transition");
	elif anim_name == "fade_out_transition":
		trans.hide();
	elif anim_name == "fade_in_endscreen":
		get_tree().set_pause(true);

func tutorial_complete():
	trans.show();
	anim_player.play("fade_in_transition");

# warning-ignore:unused_argument
# warning-ignore:unused_argument
func _on_Tween_tween_completed(object, key):
	if once:
		stage_notifier.get_node("Tween").interpolate_property(stage_notifier, "modulate", Color(0, 0, 0, 1), Color(0, 0, 0, 0), 2, Tween.TRANS_LINEAR, Tween.EASE_OUT);
		stage_notifier.get_node("Tween").start();
		once = false;
	else:
		once = true;
