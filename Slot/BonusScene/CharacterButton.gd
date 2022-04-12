extends Node2D

signal pressed;

var hovered : bool = false;
var pressed : bool = false
export(bool) var enabled : bool = false;
export(int) var id : int = 1;
export(Texture) var centertex;
export(String) var selectSoundFx;
var elementtex : Texture setget ,get_elementtex;
var default_z_index : int;
var highlighted : bool = false;

func _ready():
	default_z_index = z_index;
	$SelectPanel.connect("mouse_entered", self, "_on_mouse_entered");
	$SelectPanel.connect("mouse_exited", self, "_on_mouse_exited");
	$SelectPanel.connect("gui_input", self, "_input");

func show():
	enabled = false;
	hovered = false;
	pressed = false;
	play("Shadow2");
	#$Character.play_anim("bonus-idle", true);
	#yield($AnimationPlayer, "animation_finished");

func enable_click():
	enabled = true;
	$SelectPanel.mouse_filter = Control.MOUSE_FILTER_STOP;

func disable_click():
	$SelectPanel.mouse_filter = Control.MOUSE_FILTER_IGNORE;
	
func hide():
	enabled = false;
	play("Hide");
	disable_click();
			
func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if($SelectPanel.get_global_rect().has_point(event.global_position)):
				_on_pressed();
		
func _on_pressed():
	if(!enabled): return;
	if(!hovered): return;
	if(!is_visible_in_tree()): return;
	emit_signal("pressed");
	enabled = false;
	pressed = true;
	get_tree().set_input_as_handled();
	
func selected():
	#play("Select");
	disable_click();
	$Character.play_anim_then_loop("bonus-popup", "bonus-idle");
	Globals.singletons["Audio"].play(self.selectSoundFx);

func _on_mouse_entered():
	if(!enabled): return;
	hovered = true;
	if pressed: return;
	play("Highlight2");

func _on_mouse_exited():
	if(!enabled): return;
	hovered = false;
	if pressed: return;
	play("Shadow2");
	
func play(anim):
	$AnimationPlayer.stop();
	$AnimationPlayer.play(anim);

func highlight():
	if(highlighted): return;
	highlighted = true;
	Globals.singletons["Audio"].play("CharacterHighlight", 0.5);
	play("Highlight");
	
func unhighlight():
	if(!highlighted): return;
	highlighted = false;
	play("Shadow");
	
func character_play(anim, loop=true):
	$Character.play_anim(anim,loop);

func get_character():
	return $Character;

func show_element():
	$ElementSprite/AnimationPlayer.play("Show");
	
func hide_element():
	$ElementSprite/AnimationPlayer.play("Hide");

func get_elementtex():
	return $ElementSprite.texture;
