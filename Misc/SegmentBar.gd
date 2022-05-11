tool
extends Node

export (int) var amount : int = 0 setget set_amount, get_amount;
export (int) var nodecount : int = 5;
var _bars = {};

func _ready():
	set_amount(amount);

func set_amount(v):
	if(!is_instance_valid(self)): return;
	amount = v;
	for i in range(nodecount):
		if(!_bars.has(i) && get_node(str(i))): _bars[i] = true;
		var bar = get_node(str(i));
		
		var player = bar.get_node("AnimationPlayer");
		if(_bars[i]):
			if( i > amount ): 
				player.play("ShowGreen");
				_bars[i] = false;
			elif( i <= amount ): pass; #player.play("Show");
		else:
			if( i > amount ): pass; #player.play("Show");
			elif( i <= amount ): 
				player.play("ShowRed");
				_bars[i] = true;
	
func get_amount():
	return amount;
