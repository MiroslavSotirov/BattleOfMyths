extends Node
export (String) var assetname = "";
export (String) var propertyname = "";
export (NodePath) var node;
signal asset_swapped

func _ready():
	yield(Globals, "allready");
	if(Globals.singletons["AssetLoader"].language_loaded):
		on_lang_changed(Globals.current_language);
	else:
		Globals.singletons["AssetLoader"].connect("lang_downloaded", self, "on_lang_changed");
	
func on_lang_changed(newlang):
	get_node(node).set(propertyname, load_asset(newlang));
	emit_signal("asset_swapped");
	
	
func load_asset(newlang):
	prints("LOAD: ", "res://Translations/"+newlang+"/"+assetname);
	return load("res://Translations/"+newlang+"/"+assetname);
