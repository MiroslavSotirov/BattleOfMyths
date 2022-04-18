extends Node
class_name Game

func _ready():
	Globals.register_singleton("Game", self);
