extends Node
export (String) var assetname = "";
export (NodePath) var node;

func _ready():
	yield(Globals, "allready");
	if(Globals.singletons["AssetLoader"].language_loaded):
		on_lang_changed(Globals.current_language);
	else:
		Globals.singletons["AssetLoader"].connect("lang_downloaded", self, "on_lang_changed");
	
func on_lang_changed(newlang):
	get_node(node).set_new_state_data(load_asset(newlang), newlang, true);
	
func load_asset(newlang):	
	prints("LOAD (SPINE): ", "res://Translations/"+newlang+"/"+assetname);
	return load("res://Translations/"+newlang+"/"+assetname);
