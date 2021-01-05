extends Camera2D

onready var main = $"..";

var follow_player_y := false;

func _physics_process(delta):
	if follow_player_y:
		position = position.linear_interpolate(main.player.position, delta*8);
	elif main.player.position.x <= get_viewport_rect().size.x/2:
		position = position.linear_interpolate(get_viewport_rect().size/2, delta*4);
	else:
		position = position.linear_interpolate(Vector2(main.player.position.x, get_viewport_rect().size.y/2), delta*4);
