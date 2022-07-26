tool
extends Node

export (int) var amount : int = 0 setget set_amount, get_amount;
export (int) var nodecount : int = 5;
var _bars = {};

func _ready():
	if(!Engine.editor_hint):
		Globals.register_singleton("SegmentBar", self);
	set_amount(amount);
	
func get_bar(i):
	i = clamp(i, 0, nodecount-1);
	return get_node_or_null(str(i));

func get_current_bar(direction):
	return get_bar(amount+direction);

func set_amount(v):
	if(!is_instance_valid(self)): return;
	if(get_parent()==null): return;
	amount = v;
	for i in range(nodecount):
		if(!_bars.has(i)): _bars[i] = i > amount;
		var bar = get_bar(i);
		if(bar == null): continue;
		var player = bar.get_node("AnimationPlayer");
		if(_bars[i]):
			if( i > amount ): 
				player.play("ShowRed");
				_bars[i] = false;
			elif( i <= amount ): pass; #player.play("Show");
		else:
			if( i > amount ): pass; #player.play("Show");
			elif( i <= amount ): 
				player.play("ShowGreen");
				_bars[i] = true;
	
func get_amount():
	return amount;
