tool
extends Node
class_name ExportTest

func _get_tool_buttons(): return ["export_quality_pck"]

func export_quality_pck():
	print("Exporting...");
	pack("High");
	
func pack(folder):
	prints("Quality:",folder)
	var files = get_dir_contents("res://Quality/"+folder);
	var valid_extensions = ["png", "jpg", "webp", "tscn"];
	var paths = {};
	var folderpath = "res://Quality/"+folder+"/";
	for path in files:			
		if(!valid_extensions.has(path.get_extension())): continue
		var asset = load(path);
		if(asset is StreamTexture):
			var orgimg = load(path.replace(folderpath, "res://"));
			paths[asset.load_path] = orgimg.load_path;
		elif(asset is Texture): 
			paths[path] = path.replace(folderpath, "res://");


	var file = File.new();
	file.open(folderpath+"assets_hq.dat", File.WRITE)
	for path in paths.values(): file.store_string(path+"\n");
	file.close()
	
	var packer = PCKPacker.new()
	var pckname = "res://Quality/"+folder+".pck";
	packer.pck_start(pckname);
			
	for path in paths.keys(): 
		print(path, " -> ", paths[path])
		packer.add_file(paths[path], path)
	
	packer.add_file("res://assets_hq.dat", folderpath+"assets_hq.dat")
	
	packer.flush()
	
	print("done")	

func pack_image(path, newpath, packer):
	packer.add_file(newpath, path)
	return newpath;
		
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
