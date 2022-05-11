extends Node

var assets = [];

func _ready():
	return;
	yield(get_tree().create_timer(10.0), "timeout");	
	var success = ProjectSettings.load_resource_pack("res://Quality/High.pck", true)
	yield(get_tree(),"idle_frame");
	if success:
		print("Loaded");
		load_asset_list();
		reload_assets(get_tree().root);
	else:
		print(success)
	
func load_asset_list():
	var file = File.new();
	file.open("res://assets_hq.dat", File.READ)
	var line = file.get_line();
	while(line):
		assets.append(line);
		line = file.get_line();		
	file.close()

func reload_assets(parent):
	for child in parent.get_children():
		update_props(child, child.get_property_list());
		reload_assets(child);

func update_props(child, props):
	for prop in props:
		if(prop.type != TYPE_OBJECT): continue;
		if(child.get(prop.name) is StreamTexture): update_streamtex(child, prop.name);
		elif(child.get(prop.name) is Texture): update_tex(child, prop.name);
		elif(child.get(prop.name) is PackedScene):
			var asset = ResourceLoader.load(child.get(prop.name).resource_path, "", true);
			update_packedscene(asset);
			child.set(prop.name, asset);
					

func update_streamtex(child, propname):
	if(!assets.has(child.get(propname).load_path)): return;
	child.get(propname).load(child.get(propname).load_path);

func update_tex(child, propname):
	if(!assets.has(child.get(propname).resource_path)): return;
	var tex = ImageTexture.new();
	var image = Image.new();
	image.load(child.get(propname).resource_path);
	tex.create_from_image(image);
	child.set(propname, tex);

func update_packedscene(scene):
	for variant in scene._bundled.variants:
		if(typeof(variant) != TYPE_OBJECT): continue;
		if(variant is StreamTexture): 
			if(!assets.has(variant.load_path)): continue;
			variant.load(variant.load_path);
			
		elif(variant is PackedScene):
			update_packedscene(variant);
