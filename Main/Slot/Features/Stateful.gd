extends Node
class_name Stateful
var states := {};
var state := {} setget ,_get_state;
var current_state_key = null;
signal new_state(state, init)

func _ready():
	Globals.register_singleton("Stateful", self);
	
func update_states(init=false):
	var map = generate_map();
	if(should_update_state(map)):
		states = map;
		if(current_state_key != null):
			prints("New map", states)
			emit_signal("new_state", _get_state(), init);
	if(init):
		switch_to_state(Globals.singletons["Networking"].lastround.defaultTotal, true);

func generate_map():
	var map = null
	var data =  Globals.singletons["Networking"].lastround;
	if("features" in data):
		for feature in data.features:
			if(feature.type != "StatefulMap"): continue;
			map = _convert_map(feature.data.map);
	return map;	

func should_update_state(map=null):
	if(map == null):
		map = generate_map();
		if(map == null): return false;
	return states.hash() != map.hash();
			
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
