tool
extends Node2D
export (bool) var enabled = true;
export (Vector2) var speed;
export (Vector2) var size;

var offset : float = 0.0;

func _ready():
	offset = randf() * 1000.0;

func _process(delta):
	if(!enabled): return;
	var t = (float(OS.get_ticks_msec())/1000.0) + offset;
	position = Vector2(sin(t*speed.x), cos(t*speed.y)) * size;
