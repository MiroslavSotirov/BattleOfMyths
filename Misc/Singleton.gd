extends Node

func _ready():
	Globals.register_singleton(name, self);
