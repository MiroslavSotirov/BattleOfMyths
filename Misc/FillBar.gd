tool
extends Node

export (float) var height_size : float;
export (float) var initial_amount : float = 0.5;
export (float) var minimum_amount : float = 0.15;

var animated_amount : float setget set_animated_amount, get_animated_amount;
var current_amount : float
var target_amount : float

func _ready():
	target_amount = initial_amount;
	if(!Engine.editor_hint):
		Globals.register_singleton(name,self);

func set_animated_amount(v):
	animated_amount = lerp(minimum_amount, 1.0, v);
	var fill = 1.0 - animated_amount;	
	$Bar.margin_top = height_size * fill;	
	$Bar/BarContainer.position.y = -$Bar.margin_top;
	$BarHighlight.margin_top = $Bar.margin_top;
	$BarHighlight/BarContainer.position.y = $Bar/BarContainer.position.y;
	$BarCap.position.y = $Bar.margin_top;
	
func get_animated_amount():
	return animated_amount;

func get_bar_top_pos():
	return $BarCap.global_position;

func _process(delta):
	if(current_amount != target_amount):
		var diff = min(abs(target_amount - current_amount) * 150.0, 1.0);
		current_amount = lerp(current_amount, target_amount, 2.0 * delta);
		$BarHighlight.modulate = lerp(Color.black, Color.white, diff);
	self.animated_amount = current_amount+sin(float(OS.get_ticks_msec())/1000.0)*0.01;
	$BarCap.rotation_degrees = sin(float(OS.get_ticks_msec())/500.0)*5.0;
