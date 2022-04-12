extends Node2D

export (Vector2) var scaleoffset : Vector2;
export (Vector2) var yoffset : Vector2;
export (float, EASE) var easing : float = 1.0;

func _ready():
	Globals.connect("resolutionchanged", self, "on_resolution_changed");
	
func on_resolution_changed(landscape, portrait, screenratio, zoom):
	position.y = lerp(yoffset.x, yoffset.y, ease(clamp(screenratio, 0.0, 1.0), easing));
	scale = Vector2.ONE * lerp(scaleoffset.x, scaleoffset.y, ease(clamp(screenratio, 0.0, 1.0), easing));
