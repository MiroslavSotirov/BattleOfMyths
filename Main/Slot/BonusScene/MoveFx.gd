extends Node2D

export (PackedScene) var hitFxScene;

var speed = 1.0;
var f := 0.0;
var points = [];

signal move_complete;
	
func set_points(start,end):
	points.append(start);
	points.append(end+(Vector2(randf()-0.5, randf()-0.5)*500.0));
	points.append(end);
	
func _process(delta):
	f += delta/speed;
	global_position = _quadratic_bezier(points[0], points[1], points[2], f);
	
	if(f >= speed):
		emit_signal("move_complete")
		if(hitFxScene != null):
			var fx = hitFxScene.instance();
			get_parent().add_child(fx);
			fx.global_position = global_position;
			fx.get_node("AnimationPlayer").play("Show");

		queue_free();

func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float):
	var q0 = p0.linear_interpolate(p1, t)
	var q1 = p1.linear_interpolate(p2, t)
	return q0.linear_interpolate(q1, t)
