extends Node
class_name Game
var current_state : String = "normal";

func _ready():
	Globals.register_singleton("Game", self);

func switch_to_dragon_mode(splash=false):
	current_state = "dragon";
	$SlotContainer/Background/AnimationPlayer.play("to_dragon")
	$SlotContainer/Slot/Overlap/AnimationPlayer.play("to_dragon")
	if(splash): 
		var sprite = Globals.singletons["FreeSpinsSplash"].get_node("Sprite");
		sprite.set_skin("Dragon");
		sprite.play_anim("popup");
		yield(sprite, "animation_complete");
		sprite.play_anim("close");
		
func switch_to_tiger_mode(splash=false):
	current_state = "tiger"
	$SlotContainer/Background/AnimationPlayer.play("to_tiger")
	$SlotContainer/Slot/Overlap/AnimationPlayer.play("to_tiger")
	if(splash): 
		var sprite = Globals.singletons["FreeSpinsSplash"].get_node("Sprite");
		sprite.set_skin("Tiger");
		sprite.play_anim("popup");
		yield(sprite, "animation_complete");
		sprite.play_anim("close");
	
func switch_to_normal():
	current_state = "normal"
	$SlotContainer/Background/AnimationPlayer.play("to_normal")
	$SlotContainer/Slot/Overlap/AnimationPlayer.play("to_normal")
