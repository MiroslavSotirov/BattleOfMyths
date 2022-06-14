extends Node
class_name Game
var current_state : String = "normal";

func _ready():
	Globals.register_singleton("Game", self);

func switch_to_dragon_mode(splash=false):
	current_state = "dragon";
	$SlotContainer/Background/AnimationPlayer.play("to_dragon")
	$SlotContainer/Slot/Overlap/AnimationPlayer.play("to_dragon")
	Globals.singletons["FreeSpinsSplash"].visible = true
	if(splash): 
		var sprite = Globals.singletons["FreeSpinsSplash"].get_node("Sprite");
		sprite.set_skin("Dragon");
		sprite.play_anim_then_loop("popup","idle");
		yield(sprite, "animation_complete");
		var animplayer = Globals.singletons["FreeSpinsSplash"].get_node("AnimationPlayer")
		animplayer.play("Show")
		yield(get_tree().create_timer(1.0), "timeout");
		animplayer.play("Hide")
		sprite.play_anim("close");
		yield(sprite, "animation_complete");
		Globals.singletons["FreeSpinsSplash"].visible = false;
		
func switch_to_tiger_mode(splash=false):
	current_state = "tiger"
	$SlotContainer/Background/AnimationPlayer.play("to_tiger")
	$SlotContainer/Slot/Overlap/AnimationPlayer.play("to_tiger")
	Globals.singletons["FreeSpinsSplash"].visible = true
	if(splash): 
		var sprite = Globals.singletons["FreeSpinsSplash"].get_node("Sprite");
		sprite.set_skin("Tiger");
		sprite.play_anim_then_loop("popup","idle");
		yield(sprite, "animation_complete");
		var animplayer = Globals.singletons["FreeSpinsSplash"].get_node("AnimationPlayer")
		animplayer.play("Show")
		yield(get_tree().create_timer(1.0), "timeout");
		animplayer.play("Hide")
		sprite.play_anim("close");
		yield(sprite, "animation_complete");
		Globals.singletons["FreeSpinsSplash"].visible = false;
		
func switch_to_normal():
	current_state = "normal"
	$SlotContainer/Background/AnimationPlayer.play("to_normal")
	$SlotContainer/Slot/Overlap/AnimationPlayer.play("to_normal")

func _input(event):
	if(event is InputEventScreenTouch || event is InputEventMouseButton || event is InputEventKey):
		if(event.pressed): 
			Globals.emit_signal("skip")
			print("Skip attempt");
