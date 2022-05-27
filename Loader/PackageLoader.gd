extends Node
class_name PackageLoader

var package_name : String;
var progress : float = 0.0;
var time_max : int = 100; # msec
var completed : bool = false;
var loader = null;

signal loaded;

func _init(package_name):
	self.package_name = package_name;

func _ready():
	#loader = ResourceLoader.load_interactive("res://Game.tscn")
	prints("LOADING PACKAGE", package_name);
	if(JS.enabled):
		var path = JS.get_path()+"Packages/"+package_name+".pck";
		loader = HTTPRequest.new();
		loader.download_file = "res://"+package_name+".pck";
		loader.request(path);
		var res = yield(loader, "request_completed");
		#result, response_code, headers, body
		if(res[0] != 0):
			prints("Error downloading package ", package_name, res[0], package_name);
			progress = 1.0;
			return;

		ProjectSettings.load_resource_pack("res://"+package_name+".pck", true)
		
		progress = 1.0;
		emit_signal("loaded");
	else:
		ProjectSettings.load_resource_pack("res://Packages/"+package_name+".pck", true)
		yield(get_tree(), "idle_frame");
		progress = 1.0;
		emit_signal("loaded");
		
	prints("LOADED PACKAGE", package_name);
	
func _process(time):
	if(loader != null):
		if(loader.get_body_size() > 0 && progress < 1.0):
			progress = float(loader.get_downloaded_bytes()) / float(loader.get_body_size());
		else: 
			progress = 0.5;

func load_complete(resource):
	emit_signal("loaded", resource)
