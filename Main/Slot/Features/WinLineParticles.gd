extends CPUParticles2D

var positions = [];
var curve : Curve2D;
var position_index : int = 0;
var f : float = 0;
var startx = 75;
var endx = 75;

func _ready():
	pass;
	
func init():
	set_as_toplevel(true);
	curve = Curve2D.new();
	for p in positions:
		curve.add_point(p.global_position);
		
func _process(delta):
	for i in range(len(positions)):
		curve.set_point_position(i, positions[i].global_position);
	
	f += delta * 2.0;
		
	move_to(get_pos(f-0.3),get_pos(f),get_pos(f+0.3));
	
	if(f > len(positions)+1):
		f = -1;
		move_to(get_pos(f-0.5),get_pos(f),get_pos(f+0.5));
		$Trail.trail_points.clear();
		restart()
		
	if(f < 0):
		modulate.a = lerp(0.0, 1.0, 1+f);
		$Trail.modulate = modulate;

	if(f > len(positions)):
		modulate.a = lerp(1.0, 0.0, f-len(positions));
		$Trail.modulate = modulate;
		
func move_to(a,b,c):
	var pos = _quadratic_bezier(a, b, c, 0.5);
	global_position = pos;

func get_pos(i):
	if(i < 0):
		return Vector2(-startx * (abs(i)), 0) + curve.interpolatef(0);
		
	var n = len(positions)-1;
	if(i > n):
		return Vector2(endx * (abs(i)-n), 0) + curve.interpolatef(n);
		
	return curve.interpolatef(i);

func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float):
	var q0 = p0.linear_interpolate(p1, t)
	var q1 = p1.linear_interpolate(p2, t)
	var r = q0.linear_interpolate(q1, t)
	return r
