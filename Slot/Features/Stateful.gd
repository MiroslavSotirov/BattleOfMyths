extends Node
class_name Stateful
var states := {};
var state := {} setget ,_get_state;
var current_state_key = null;
signal new_state(state, init)

func _ready():
	Globals.register_singleton("Stateful", self);
	
func update_states(init=false):
	var map = null
	var data =  Globals.singletons["Networking"].lastround;
	if("features" in data):
		for feature in data.features:
			if(feature.type != "StatefulMap"): continue;
			map = _convert_map(feature.data.map);
	if(map == null): return;
	if(states.hash() != map.hash()):
		states = map;
		if(current_state_key != null):
			prints("New map", states)
			emit_signal("new_state", _get_state(), init);
		elif(init):
			switch_to_state(data.defaultTotal, true);
			
			
func switch_to_state(key,init=false):
	current_state_key = float(key);
	prints("New state", current_state_key, _get_state());
	emit_signal("new_state", _get_state(), init);
	
func _get_state():
	if(!states.has(current_state_key)): states[current_state_key] = {};
	return states[current_state_key]
	
func _convert_map(map):
	var newmap = {};
	for key in map.keys():
		newmap[float(key)] = map[key];
	return newmap;
