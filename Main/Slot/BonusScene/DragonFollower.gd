extends Node2D

var duration : float = 2.0;
var targetpos : Array = [];
var t : float = 0.0
var curve : Curve;
var startx : float = 0.0;
var endx : float = 0.0;
var headrot : float;

func init(targetpos):
	self.targetpos = targetpos;
	curve = Curve.new();
	startx = targetpos[0].x;
	endx = targetpos[len(targetpos)-1].x;
	
	for p in targetpos:
		p.x = (p.x - startx)/(endx - startx);
		curve.add_point(p);

func _process(delta):
	#print(global_position.distance_to(targetpos))
	t += delta;
	var n = t/duration;
	global_position.y = curve.interpolate(n);
	global_position.x = lerp(startx, endx, n);
	
	for i in len($Line2D.gradient.colors):
		var c = $Line2D.gradient.colors[i];
		c.a = modulate.a;
		$Line2D.gradient.set_color(i, c);
	
	if(n < 1.0):
		var nextpos = Vector2();
		n += 0.01;
		nextpos.y = curve.interpolate(n);
		nextpos.x = lerp(startx, endx, n);
		var targetrot = nextpos.angle_to_point(global_position);
		headrot = lerp_angle(headrot, targetrot, 2.0*delta);
		$SpineSpriteExtension.global_rotation = headrot;

func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float):
	var q0 = p0.linear_interpolate(p1, t)
	var q1 = p1.linear_interpolate(p2, t)
	var r = q0.linear_interpolate(q1, t)
	return r

func play(anim):
	$AnimationPlayer.play(anim)
