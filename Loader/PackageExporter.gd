tool
extends Node
class_name PackageExporter

export(Array,String,DIR) var targetpaths : Array;
export(Array,String,DIR) var ignorepaths : Array;
export(bool) var is_loader : bool = false;

func _get_tool_buttons(): return ["export_pck"]

func _ready():
	var do_export = false;
	for argument in OS.get_cmdline_args():
		if(argument == "-export_pck"): 
			do_export = true;
			break;
		
	if(do_export):
		export_pck();

func export_pck():
	prints("Exporting", name);
	
	var valid_extensions = ["png", "jpg", "webp", "tscn", "tres", "gd", "ttf", "json"];
	var paths = {};
	
	for folder in targetpaths:
		print(folder);
		var files = get_dir_contents(folder);
		for path in files:
			if(!valid_extensions.has(path.get_extension())): continue
			paths[path] = path;
		#var asset = load(path);
		#if(asset is StreamTexture):
		#	var orgimg = load(path.replace(folderpath, "res://"));
		#	paths[asset.load_path] = orgimg.load_path;
		#elif(asset is Texture): 
		#	paths[path] = path.replace(folderpath, "res://");

	var packer = PCKPacker.new()
	var pckname = "res://packages/"+name+".pck";
	packer.pck_start(pckname);
			
	for path in paths.keys(): 
		print(path, " -> ", paths[path])
		packer.add_file(paths[path], path)
		
	if(is_loader):
		ProjectSettings.save_custom("res://project.binary")
		#packer.add_file("res://project.godot", "res://project.godot")
		#print("res://project.godot -> res://project.godot")
		packer.add_file("res://project.binary", "res://project.binary")
		print("res://project.binary -> res://project.binary")
		
	packer.flush()
	
	print("done")	

func get_dir_contents(rootPath: String) -> Array:
	var files = []
	var dir = Directory.new()

	if dir.open(rootPath) == OK:
		dir.list_dir_begin(true, false)
		_add_dir_contents(dir, files)
	else:
		push_error("An error occurred when trying to access the path.")

	return files

func _add_dir_contents(dir: Directory, files : Array):
	var file_name = dir.get_next()
		
	while (file_name != ""):
		var path = dir.get_current_dir() + "/" + file_name

		if dir.current_is_dir():
			#print("Found directory: %s" % path)
			var subDir = Directory.new()
			subDir.open(path)
			subDir.list_dir_begin(true, false)
			_add_dir_contents(subDir, files)
		else:
			#print("Found file: %s" % path)
			files.append(path)

		file_name = dir.get_next()
		while(file_name.begins_with(".")): 
			file_name = dir.get_next()

	dir.list_dir_end()

