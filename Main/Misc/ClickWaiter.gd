extends Control
signal pressed;

export(bool) var enabled : bool = false;

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed(): _on_pressed();
		
func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed(): _on_pressed();
		
func _on_pressed():
	if(!enabled): return;
	if(!is_visible_in_tree()): return;
	emit_signal("pressed");
	enabled = false;
	
