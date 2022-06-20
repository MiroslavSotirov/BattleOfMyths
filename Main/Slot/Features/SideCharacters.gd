extends Node

func _ready():
	Globals.register_singleton("SideCharacters", self);
	
func play(anim, delay=0.0):
	if(delay > 0.0): yield(get_tree().create_timer(delay), "timeout");
	$AnimationPlayer.play(anim);

func spine_play(character, anim):
	get_node(character).play_anim_then_loop(anim, "idle");
