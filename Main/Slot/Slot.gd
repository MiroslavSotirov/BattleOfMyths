extends Control
const TileData = preload("TileData.gd")

export (String) var reel_spin_sfx : String;
export (String) var reel_stop_sfx : String;
export (float) var reel_stop_volume : float;
export (String) var reel_start_sfx : String;

export (Array) var availableTiles : Array = [];
export (Array, NodePath) var reels : Array = [];
export (bool) var testSpinStart : bool setget _test_spin_start_set;
export (bool) var testSpinStop : bool setget _test_spin_stop_set;
export (float) var reelStartDelay = 0.01;
export (float) var reelStopDelay = 0.01;
export (int) var invisible_tile = 0;

var allspinning : bool setget , _get_allspinning;
var spinning : bool setget , _get_spinning;
#var stopped : bool setget , _get_stopped;
#var stopping : bool setget , _get_stopping;

var targetdata : Array = [];
var reels_spinning : int = 0;

var all_tiles : Array = [];

signal apply_tile_features(spindata, reeldata);
signal onstartspin;
signal onstopping;
signal onstopped;
signal ontilesremoved

func _ready():
	Globals.register_singleton("Slot", self);
	testSpinStart = false;
	testSpinStop = false;
	yield(Globals, "allready")
	for i in range(len(reels)):
		reels[i] = get_node(reels[i]);
		reels[i].initialize(i, availableTiles);
		reels[i].connect("onstopped", self, "_on_reel_stopped");

	Globals.visibleTilesCount = reels[0].visibleTilesCount;
	Globals.visibleReelsCount = len(reels);

#func assign_tiles(tiles_array):
#	if (tiles_array.size() != reels.size()):
#		push_error("Tiles data cannot be set due to mismatching reels count");
#
#	for i in range(tiles_array.size()):
#		reels[i].assign_tiles(tiles_array[i])

func set_initial_screen(data):
	var init_data = parse_spin_data(data);
	#	yield(get_tree().create_timer(5), "timeout");
	for i in range(len(reels)):
		reels[i].set_initial_screen(init_data[i]);
	
func _on_reel_stopping_anim(index):
		if(index == len(self.reels) - 1):
			Globals.singletons["Audio"].fade(reel_spin_sfx, 1, 0, 300)
		
func _on_reel_stopped(index):
	reels_spinning -= 1;
#	if(reels_spinning == 0): emit_signal("onstopped");

func _test_spin_start_set(val):
	if(!val): return;
	start_spin();
	testSpinStart = false;

func _test_spin_stop_set(val):
	if(!val): return;
	stop_spin();
	testSpinStop = false;

func start_spin():
	if(self.spinning): return;
	if(self.reel_start_sfx): Globals.singletons["Audio"].play(self.reel_start_sfx);
	if(self.reel_spin_sfx): Globals.singletons["Audio"].loop(self.reel_spin_sfx);
	
	reels_spinning = 0;
	for reel in reels:
		yield(get_tree().create_timer(reelStartDelay), "timeout");
		reel.start_spin();
		reels_spinning += 1;

	emit_signal("onstartspin");
	
func stop_spin(data = null):
	var end_data = parse_spin_data(data);
	var promises = [];

	for i in range(len(reels)):
		promises.push_back(reels[i].stop_spin(end_data[i]));

	yield(Promise.all(promises), "completed");
	emit_signal("onstopped");

func _get_spinning():
	return reels_spinning > 0;
	
func _get_allspinning():
	for reel in reels: 
		if(!reel.is_spinning): return false

	return true;
	
#func _get_stopped():
#	for reel in reels: if(!reel.stopped): return false;
#	for reel in reels: print(reel);
#	return true;
	
#func _get_stopping():
#	for reel in reels: if(reel.stopping): return true;
#	for reel in reels: print(reel);
#	return false;
	
func parse_spin_data(data):
	if (data == null): return get_safe_spin_data();
	if (!("view" in data)): return get_safe_spin_data();
#	emit_signal("apply_tile_features", data, spind ata); #TODO check what this signal is doing
	if (!("features" in data)): return data.view;
	
	var view = data.view.duplicate(true);

	for feature in data.features:
		if(feature.type == "FatTile"):
			var tiles_count = reels[feature.data.x].visibleTilesCount;
			var height = tiles_count - abs(feature.data.y);
			var width = feature.data.w;
			var direction = 1 if feature.data.y + feature.data.h <= tiles_count else -1;
			var i = feature.data.x;
			var j = feature.data.y + feature.data.h - 1 if direction == 1 else max(0, feature.data.y);
			
			if (view[i][j] != feature.data.tileid):
				push_error("wrong fat tile data");
				continue;

			for k in range(height):
				for l in range(width):
					if (k == 0 && l == 0):
						view[i][j] = view[i][j] * direction;
					else:
						view[i + l][j - k * direction] = invisible_tile;

	return view;

func get_safe_spin_data():
	var spindata = [];
	for i in range(len(reels)):
		spindata.append([]);
		for n in range(reels[i].visibleTilesCount):
			spindata[i].append(self.availableTiles[i]);

	return spindata; 

func get_tile_at(x, y):
	return reels[x].get_tile_at(y);

func add_data(data):
	var end_data = parse_spin_data(data);
#	var end_data = data;

	var size = end_data.size();
	var promises = Mapper.callOnElements(reels, "add_tiles", end_data);

	yield(Promise.all(promises), "completed");

func remove_tiles(data):
	print("removing tiles ", data);
	var promises = [];
	for i in data.keys():
		promises.push_back(reels[i].remove_tiles(data[i]));
	
	yield(Promise.all(promises), "completed");
	emit_signal("ontilesremoved");