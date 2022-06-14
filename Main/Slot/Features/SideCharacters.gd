extends Node

func _ready():
	Globals.register_singleton("SideCharacters", self);
	
func play(anim):
	$AnimationPlayer.play(anim);
