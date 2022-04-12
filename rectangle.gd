extends Node2D

func _draw():
	var side = 200;
	var color = Color(1,0,0);
	var rect = Rect2(-side / 2, -side / 2, side, side);
	draw_rect(rect, color);
