extends Node
class_name LoadingSystem

export (Array, String) var required_packages : Array = [];
export (Array, String) var optional_packages : Array = [];

var loaded_packages : Array = [];

var loaders = [];
var progress : float = 0.0;

signal asset_loaded(name, asset);
signal package_loaded(name);
signal required_packages_loaded;
signal optional_packages_loaded;

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS;
	
func start():
	load_required_packages();
	yield(self, "required_packages_loaded");
	load_optional_packages();

func load_required_packages():
	for pck_name in required_packages:		
		load_package(pck_name);
	
	var n = 1.0/len(required_packages);
	while(progress < 1.0):
		progress = 0.0;
		for loader in loaders: progress += loader.progress * n;
		if(JS.enabled):
			JS.output(progress * 0.5, "elysiumgameloadingprogress")
		yield(get_tree(), "idle_frame");
		
	emit_signal("required_packages_loaded");
	
func load_optional_packages():
	for pck_name in optional_packages:
		load_package(pck_name);
		yield(self, "package_loaded");
		
	emit_signal("optional_packages_loaded");

func load_package(pck_name):
	var loader = PackageLoader.new(pck_name);
	if("translation_" in pck_name): loader.translation = true;
	add_child(loader);
	loaders.append(loader);
	loader.connect("loaded", self, "load_package_completed", [pck_name]);
	return loader;
	
func load_package_completed(pck_name):
	loaded_packages.append(pck_name)
	emit_signal("package_loaded", pck_name);
	
func load_asset(assetname):
	var loader = AssetLoader.new(assetname);
	add_child(loader);
	loaders.append(loader);
	loader.connect("loaded", self, "load_asset_completed", [assetname]);
	return loader;

func load_asset_completed(assetname, asset):
	emit_signal("asset_loaded", assetname, asset);
	
func is_pck_loaded(name):
	if(loaded_packages.has(name)):
		call_deferred("emit_signal", name);
	else:
		show_loading_screen(name);
	return self;

func show_loading_screen(name):
	get_tree().paused = true;
	print("WAITING...");
	while yield(self.is_pck_loaded(name), "package_loaded") != name: pass
	get_tree().paused = false;
	print("DONE!");

#while yield(PackageLoader.is_pck_loaded(name), "package_loaded") != name: pass
#var bonus = load(bonuspath);
