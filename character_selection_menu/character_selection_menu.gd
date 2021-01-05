extends Control

func _on_male_select_pressed():
	global.character = "male";
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://main/main.tscn");


func _on_female_select_pressed():
	global.character = "female";
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://main/main.tscn");
