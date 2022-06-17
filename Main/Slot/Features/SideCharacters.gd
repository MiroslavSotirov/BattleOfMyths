extends Node

func _ready():
	Globals.register_singleton("SideCharacters", self);
	
func play(anim):
	$AnimationPlayer.play(anim);

func spine_play(character, anim):
	get_node(character).play_anim_then_loop(anim, "idle");
