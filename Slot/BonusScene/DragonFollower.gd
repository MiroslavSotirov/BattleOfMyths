extends Node2D

func _ready():
	pass # Replace with function body.

func _process(delta):
	var multiplier = 3.0;
	var targetpos = get_global_mouse_position();
	var targetangle = global_position.angle_to_point(targetpos);

	var rotation_speed = 2.5 + (sin(OS.get_ticks_msec()/500.0*multiplier) * 2.0);
	rotation_speed = clamp(rotation_speed, -1.0, 1.0)  * multiplier * delta;
	global_rotation = lerp_angle(global_rotation, targetangle, rotation_speed);
	
	var speed = 300.0 + ((cos(OS.get_ticks_msec()/500.0*multiplier)+(rotation_speed/5.0)) * 10.0);
	var dir = -Vector2.RIGHT + (Vector2.UP * 1.5 * sin(OS.get_ticks_msec()/1000.0*multiplier)/3.0);
	
	global_position = to_global(dir * delta * speed * multiplier);
