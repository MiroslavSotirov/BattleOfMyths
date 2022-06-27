extends Node2D

var duration : float = 2.0;
var targetpos : Array = [];
var t : float = 0.0
var headrot : float;
var lastid = -1;

signal hit;
signal hide_end;

func init(targetpos):
	self.targetpos = targetpos;

func _process(delta):
	#print(global_position.distance_to(targetpos))
	var startx = targetpos[0].global_position.x-200.0;
	var endx = targetpos[len(targetpos)-1].global_position.x+200.0;

	t += delta;
	var n = t/duration;

	global_position.y = get_y_pos_tweened(n);
	global_position.x = lerp(startx, endx, n);
	
	var id = floor(n*len(targetpos));
	if(id == lastid+1):
		lastid = id;
		emit_signal("hit");
		print("hit ",lastid);
		
	for i in len($Line2D.gradient.colors):
		var c = $Line2D.gradient.colors[i];
		c.a = modulate.a;
		$Line2D.gradient.set_color(i, c);
	
	if(n < 1.0):
		var nextpos = Vector2();
		n += delta;
		nextpos.y = get_y_pos_tweened(n);
		nextpos.x = lerp(startx, endx, n);
		var targetrot = nextpos.angle_to_point(global_position);
		headrot = lerp_angle(headrot, targetrot, 4.0*delta);
		$SpineSpriteExtension.global_rotation = headrot;

func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float):
	var q0 = p0.linear_interpolate(p1, t)
	var q1 = p1.linear_interpolate(p2, t)
	var r = q0.linear_interpolate(q1, t)
	return r

func play(anim):
	$AnimationPlayer.play(anim)
	
func hide():
	play("Hide");
	yield($AnimationPlayer, "animation_finished")
	emit_signal("hide_end");
	
func get_y_pos_tweened(n):
	var a = lerp(get_y_pos(n-0.01), global_position.y, n);
	var b = lerp(global_position.y, get_y_pos(n+0.01), n);
	return lerp(a, b, n);

func get_y_pos(n):
	var id = floor(n*len(targetpos));
	if(id <= 0): return targetpos[0].global_position.y;
	if(id >= len(targetpos)-1): return targetpos[len(targetpos)-1].global_position.y;
	
	var dur = fmod(n, 1.0/float(len(targetpos)));
	return lerp(
		targetpos[id-1].global_position.y,
		targetpos[id].global_position.y,
		dur*float(len(targetpos))
	);
