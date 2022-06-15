extends Node
class_name Game
var current_state : String = "normal";

func _ready():
	Globals.register_singleton("Game", self);

func switch_to_dragon_mode(splash=false):
	current_state = "dragon";
	$SlotContainer/Background/AnimationPlayer.play("to_dragon")
	$SlotContainer/Slot/Overlap/AnimationPlayer.play("to_dragon")
	Globals.singletons["Audio"].change_track("background", "Dragon Theme", 1000, 1, 1, 1);
	Globals.singletons["Audio"].fade_track("melody", 1, 0, 1000, 0);
	Globals.singletons["FreeSpinsSplash"].visible = true
	Globals.singletons["SideCharacters"].play("HideTiger");
	if(splash): 
		Globals.singletons["Audio"].play("Dragon Free Spins");
		var sprite = Globals.singletons["FreeSpinsSplash"].get_node("Sprite");
		sprite.set_skin("Dragon");
		sprite.play_anim_then_loop("popup","idle");
		yield(sprite, "animation_complete");
		var animplayer = Globals.singletons["FreeSpinsSplash"].get_node("AnimationPlayer")
		animplayer.play("Show")
		yield(get_tree().create_timer(1.0), "timeout");
		animplayer.play("Hide")
		sprite.play_anim("close", false);
		yield(get_tree().create_timer(2.0), "timeout");
		Globals.singletons["FreeSpinsSplash"].visible = false;
		
func switch_to_tiger_mode(splash=false):
	current_state = "tiger"
	$SlotContainer/Background/AnimationPlayer.play("to_tiger")
	$SlotContainer/Slot/Overlap/AnimationPlayer.play("to_tiger")
	Globals.singletons["Audio"].change_track("background", "Tiger Theme", 1000, 1, 1, 1);
	Globals.singletons["Audio"].fade_track("melody", 1, 0, 1000, 0);
	Globals.singletons["FreeSpinsSplash"].visible = true
	Globals.singletons["SideCharacters"].play("HideDragon");
	if(splash): 
		Globals.singletons["Audio"].play("Tiger Free Spins");
		var sprite = Globals.singletons["FreeSpinsSplash"].get_node("Sprite");
		sprite.set_skin("Tiger");
		sprite.play_anim_then_loop("popup","idle");
		yield(sprite, "animation_complete");
		var animplayer = Globals.singletons["FreeSpinsSplash"].get_node("AnimationPlayer")
		animplayer.play("Show")
		yield(get_tree().create_timer(1.0), "timeout");
		animplayer.play("Hide")
		sprite.play_anim("close", false);
		yield(get_tree().create_timer(2.0), "timeout");
		Globals.singletons["FreeSpinsSplash"].visible = false;
		
func switch_to_normal_mode():
	if(current_state == "dragon"): 	Globals.singletons["SideCharacters"].play("ShowTiger");
	if(current_state == "tiger"): 	Globals.singletons["SideCharacters"].play("ShowDragon");
	Globals.singletons["Audio"].change_track("background", "Foundation", 1000, 1, 1, 1);
	current_state = "normal"
	$SlotContainer/Background/AnimationPlayer.play("to_normal")
	$SlotContainer/Slot/Overlap/AnimationPlayer.play("to_normal")
	Globals.singletons["SideCharacters"].play("HideDragon");
		
func _input(event):
	if(event is InputEventScreenTouch || event is InputEventMouseButton || event is InputEventKey):
		if(event.pressed): 
			Globals.emit_signal("skip")
			print("Skip attempt");
