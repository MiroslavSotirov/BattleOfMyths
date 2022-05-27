extends Control

signal pressed;

var hovered : bool = false;
var pressed : bool = false
export(bool) var enabled : bool = false;

func _init():
	connect("mouse_entered", self, "_on_mouse_entered");
	connect("mouse_exited", self, "_on_mouse_exited");

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed(): _on_pressed();
		
func _on_pressed():
	if(!enabled || !hovered || pressed): return;
	if(!is_visible_in_tree()): return;	
	emit_signal("pressed");
	pressed = true;

func _on_mouse_entered():
	#if pressed: return;
	hovered = true;

func _on_mouse_exited():
	#if pressed: return;
	hovered = false;
