extends Control

onready var anim_player = $AnimationPlayer;
onready var transition = $transition;

func _ready():
	OS.window_fullscreen = true;
	anim_player.play("fade_in");

func _on_new_game_pressed():
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://character_selection_menu/character_selection_menu.tscn");

func _on_exit_pressed():
	get_tree().quit();


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "fade_in":
		transition.hide();
