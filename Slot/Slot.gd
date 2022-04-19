extends Control
const TileData = preload("TileData.gd")

export (String) var reel_spin_sfx : String;
export (String) var reel_stop_sfx : String;
export (float) var reel_stop_volume : float;
export (String) var reel_start_sfx : String;

export (Array) var availableTiles : Array = [];
export (Array) var reels : Array = [];
export (bool) var testSpinStart : bool setget _test_spin_start_set;
export (bool) var testSpinStop : bool setget _test_spin_stop_set;
export (float) var reelStartDelay = 0.01;
export (float) var reelStopDelay = 0.01;

var allspinning : bool setget , _get_allspinning;
var spinning : bool setget , _get_spinning;
var stopped : bool setget , _get_stopped;
var stopping : bool setget , _get_stopping;

var targetdata : Array = [];
var reels_spinning : int = 0;

var all_tiles : Array = [];

signal apply_tile_features(spindata, reeldata);
signal onstartspin;
signal onstopping;
signal onstopped;

func _ready():
	Globals.register_singleton("Slot", self);
	testSpinStart = false;
	testSpinStop = false;
	yield(Globals, "allready")
	for i in range(len(reels)):
		reels[i] = get_node(reels[i]);
#		reels[i].slot = self;
#		reels[i].index = i;
		reels[i].initialize(i, availableTiles);
		# reels[i].connect("onstoppinganim", self, "_on_reel_stopping_anim");
		reels[i].connect("onstopped", self, "_on_reel_stopped");

	Globals.visible_tiles_count = reels[0].visibleTileCount;
	Globals.visible_reels_count = len(reels);
#
#func assign_tiles(tilearray):
#	for x in range(Globals.visible_reels_count):
#		for y in range(Globals.visible_tiles_count):
#			get_tile_at(x,y).setTileData(TileData.new(tilearray[x][y]));
#
#	for tile in all_tiles:
#		tile.check_underneath_fat_tile();
#
#	for tile in all_tiles:
#		tile.show_image();

func assign_tiles(tiles_array):
	if (tiles_array.size() != reels.size()):
		push_error("Tiles data cannot be set due to mismatching reels count");

	for i in range(tiles_array.size()):
		reels[i].assign_tiles(tiles_array[i])
			
func _on_reel_stopping_anim(index):
		if(index == len(self.reels) - 1):
			Globals.singletons["Audio"].fade(reel_spin_sfx, 1, 0, 300)
		
func _on_reel_stopped(index):
	reels_spinning -= 1;
	if(reels_spinning == 0): emit_signal("onstopped");

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
	
	for reel in reels:
		reel.start_spin();
		reels_spinning += 1;
		yield(get_tree().create_timer(reelStartDelay), "timeout");
	
	emit_signal("onstartspin");
	
func stop_spin(data = null):
	var end_data = parse_spin_data(data) if data != null else get_safe_spin_data();
	for i in range(len(reels)):
		reels[i].stop_spin(end_data[i]);

#	if (self.stopping || self.stopped): return;
#
#	targetdata = parse_spin_data(data) if data != null else get_safe_spin_data();
#	for i in range(len(reels)):
#		reels[i].stop_spin(targetdata[i]);
#		yield(get_tree().create_timer(reelStopDelay), "timeout")
#	emit_signal("onstopping");

func _get_spinning():
	return reels_spinning > 0;
	
func _get_allspinning():
	return reels_spinning == len(reels);
	
func _get_stopped():
	for reel in reels: if(!reel.stopped): return false;
	return true;
	
func _get_stopping():
	for reel in reels: if(reel.stopping): return true;
	return false;
	
#func parse_spin_data(data):
#	var spindata = [];
#	for reelids in data["view"]:
#		var reeldata = [];
#		for tileid in reelids:
#			reeldata.append(TileData.new(tileid))
#		spindata.append(reeldata);
#
#	emit_signal("apply_tile_features", data, spindata);
#
#	return spindata;
func parse_spin_data(data):
#	emit_signal("apply_tile_features", data, spindata); #TODO check what this signal is doing
	
	return data["view"];
	
#func get_safe_spin_data():
#	var spindata = [];
#	for i in range(len(reels)):
#		spindata.append([]);
#		for n in range(reels[i].visibleTileCount):
#			spindata[i].append(TileData.new(self.availableTiles[i]));
#
#	return spindata;

func get_safe_spin_data():
	var spindata = [];
	for i in range(len(reels)):
		spindata.append([]);
		for n in range(reels[i].visibleTileCount):
			spindata[i].append(self.availableTiles[i]);

	return spindata;

func get_tile_at(x,y):
	return reels[x].get_tile_at(y);
