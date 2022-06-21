extends Node2D

export (Vector2) var scaleoffset : Vector2;
export (Vector2) var yoffset : Vector2;
export (float, EASE) var easing : float = 1.0;
export(bool) var autohide = true;
var _value = 0.0;
var shown = true;

func _ready():
	Globals.connect("resolutionchanged", self, "on_resolution_changed");
	
func on_resolution_changed(landscape, portrait, screenratio, zoom):
	_value = ease(clamp(screenratio, 0.0, 1.0), easing);
	position.y = lerp(yoffset.x, yoffset.y, _value);
	scale = Vector2.ONE * lerp(scaleoffset.x, scaleoffset.y, _value);

func _process(delta):
	if(!autohide): return;
	if(_value < 0.5):
		var infs = "in_freespins" in Globals.fsm_data && Globals.fsm_data["in_freespins"];
		if(Globals.singletons["WinBar"].shown || Globals.singletons["TotalWinBar"].shown || infs):
			if(shown): 
				$AnimationPlayer.play("Hide");
				shown = false;
		else:
			if(!shown):
				$AnimationPlayer.play("Show");
				shown = true;
	else:
		if(!shown):
			$AnimationPlayer.play("Show");
			shown = true;
