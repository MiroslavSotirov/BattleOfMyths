extends Node
class_name Game

func _ready():
	Globals.register_singleton("Game", self);

func switch_to_dragon_mode():
	$SlotContainer/Background/AnimationPlayer.play("to_dragon")
	$SlotContainer/Slot/Overlap/AnimationPlayer.play("to_dragon")
	
func switch_to_tiger_mode():
	$SlotContainer/Background/AnimationPlayer.play("to_tiger")
	$SlotContainer/Slot/Overlap/AnimationPlayer.play("to_tiger")

func switch_to_normal():
	$SlotContainer/Background/AnimationPlayer.play("to_normal")
	$SlotContainer/Slot/Overlap/AnimationPlayer.play("to_normal")
