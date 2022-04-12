extends Control

signal pressed;

var hovered : bool = false;
var pressed : bool = false
export(bool) var enabled : bool = false;

func _init():
	connect("mouse_entered", self, "_on_mouse_entered");
	connect("mouse_exited", self, "_on_mouse_exited");

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed(): _on_pressed();
		
func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed(): _on_pressed();
		
func _on_pressed():
	if(!enabled || pressed): return;
	if(!is_visible_in_tree()): return;
	$Centering/ButtonRoot/ButtonNormal.visible = false;
	$Centering/ButtonRoot/ButtonHover.visible = false;
	$Centering/ButtonRoot/ButtonPressed.visible = true;
	$AnimationPlayer.play("Pressed");	
	emit_signal("pressed");
	pressed = true;

func _on_mouse_entered():
	hovered = true;
	if pressed: return;
	$Centering/ButtonRoot/ButtonNormal.visible = false;
	$Centering/ButtonRoot/ButtonHover.visible = true;

func _on_mouse_exited():
	hovered = false;
	if pressed: return;
	$Centering/ButtonRoot/ButtonHover.visible = false;
	$Centering/ButtonRoot/ButtonNormal.visible = true;
