extends Node

func _ready():
	Globals.register_singleton("SideCharacters", self);
	get_node("Tiger").play_anim("idle", true, 0.5);
	get_node("Dragon").play_anim("idle", true, 0.5);
	
func play(anim, delay=0.0):
	if(delay > 0.0): yield(get_tree().create_timer(delay), "timeout");
	$AnimationPlayer.play(anim);

func spine_play(character, anim):
	var chr = get_node(character);
	chr.play_anim(anim, false);
	yield(chr, "animation_complete");
	chr.play_anim("idle", true, 0.5);
