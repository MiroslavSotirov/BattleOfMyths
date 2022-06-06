extends Node
class_name Game
var current_state : String = "normal";

func _ready():
	Globals.register_singleton("Game", self);

func switch_to_dragon_mode():
	current_state = "dragon";
	$SlotContainer/Background/AnimationPlayer.play("to_dragon")
	$SlotContainer/Slot/Overlap/AnimationPlayer.play("to_dragon")
	
func switch_to_tiger_mode():
	current_state = "tiger"
	$SlotContainer/Background/AnimationPlayer.play("to_tiger")
	$SlotContainer/Slot/Overlap/AnimationPlayer.play("to_tiger")

func switch_to_normal():
	current_state = "normal"
	$SlotContainer/Background/AnimationPlayer.play("to_normal")
	$SlotContainer/Slot/Overlap/AnimationPlayer.play("to_normal")
