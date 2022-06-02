extends Node2D
var multiplier : int = 1;

func _ready():
	Globals.register_singleton("WinMultiplier", self);
	
func set_multiplier(n):
	$Root/Label.text = String(n);
	if(n > multiplier):
		$AnimationPlayer.play("ChangeUp")
	multiplier = n;
