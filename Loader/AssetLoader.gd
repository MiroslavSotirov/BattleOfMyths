extends Node
class_name AssetLoader

var asset_name : String;
var progress : float = 0.0;
var time_max : int = 10; # msec
var loader;
var asset;
signal loaded(resource);

func _init(asset_name):
	self.asset_name = asset_name;

func _ready():
	loader = ResourceLoader.load_interactive(asset_name)
	
func _process(time):
	var t = OS.get_ticks_msec()
	# Use "time_max" to control for how long we block this thread.
	while progress < 1.0:
		var err = loader.poll()

		if err == ERR_FILE_EOF: # Finished loading.
			load_complete(loader.get_resource());
			break
		elif err == OK:
			progress = float(loader.get_stage()) / float(loader.get_stage_count());
		else: # Error during loading.
			prints("ERROR LOADING ASSET", asset_name, err);
			
		yield(get_tree(), "idle_frame");

func load_complete(resource):
	asset = resource;
	emit_signal("loaded", resource)
