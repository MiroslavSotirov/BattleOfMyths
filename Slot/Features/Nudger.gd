extends Node

signal activationend;
signal nudgeend;

export (PackedScene) var nudgefx_scene;
export (String) var nudgefx_sound;

var nudge_values = {};
var reels_to_nudge = [];
var base_chance = 40;
var nudge_chances = {
	2 : { 1:55, 2:45},
	3 : { 1:35, 2:45, 3:20},
	4 : { 1:10, 2:40, 3:30, 4:20 },
	5 : { 1:5, 2:10, 3:35, 4:30, 5:20 }	
}

func _ready():
	Globals.register_singleton("Nudger",self);
	yield(Globals, "allready")
	Globals.singletons["Slot"].connect("apply_tile_features", self, "apply_to_reels");
	yield(get_tree(),"idle_frame");
	for reel in Globals.singletons["Slot"].reels:
		nudge_values["reel"+str(reel.index)] = 0;

func apply_to_reels(spindata, reelsdata):
	reels_to_nudge.clear();
	
	var chance = randf() * 100.0;
	if(chance > base_chance): return;
	
	var fat_tiles = [];
	for feature in spindata.features:
		if(feature.type != "FatTile"): continue;
		if(feature.data.y != 0): continue;
		fat_tiles.append(feature);
	var fat_tile_count = len(fat_tiles);
	if(fat_tile_count == 0): return
	var move_count = 0;
	if(fat_tile_count == 1): move_count = 1;
	else:
		chance = randf() * 100.0;
		for i in nudge_chances[fat_tile_count].keys():
			chance -= nudge_chances[fat_tile_count][i];
			if(chance < 0):
				move_count = i;
				break;
	
	fat_tiles.shuffle();
	for i in range(move_count):
		var feature = fat_tiles[i];
		var reelid = feature.data.x;
		var safetile = 0;
		var tiles = Globals.singletons["Slot"].availableTiles.duplicate();
		if(reelid > 0):
			for id in reelsdata[reelid-1]: tiles.erase(id);
		if(reelid < len(Globals.singletons["Slot"].reels)-1):
			for id in reelsdata[reelid+1]: tiles.erase(id);
		safetile = tiles[randi()%len(tiles)];
		var data = {
			"reel" : Globals.singletons["Slot"].reels[feature.data.x],
			"direction" : 0,
			"safetile": safetile
		}
		data.direction = -1 if (randi() % 2) == 1 else 1;
		#data.direction *= 1 + (randi() % 2);
		reels_to_nudge.append(data);
	
		for n in range(abs(data.direction)):
			if(data.direction > 0):
				data.reel.stop_tile_offset_top.push_front(TileData.new(data.safetile));
			else:
				data.reel.stop_tile_offset_bottom.push_front(TileData.new(data.safetile));
	prints(reels_to_nudge)
	
func has_feature():
	return len(reels_to_nudge) > 0;
	
func activate():
	if(false): emit_signal("activationend");
	if(self.nudgefx_sound): Globals.singletons["Audio"].play(self.nudgefx_sound);
	for data in reels_to_nudge:
		var distance_to_move = data.direction * data.reel.tileDistance;
		#distance_to_move += data.direction;
		nudge_reel(data.reel, distance_to_move);
	yield(self,"nudgeend");
	
	emit_signal("activationend");

	#Globals.singletons["Slot"].reels[0].move();

func nudge_reel(reel, targetdistance):
	reel.stopping = false;
	reel.spinning = true;
	var duration = 0.6;
	var tween = Tween.new();
	add_child(tween);
	var index = "reel"+str(reel.index);
	tween.interpolate_property(self, "nudge_values:"+index,
		0, targetdistance, duration,
		Tween.TRANS_QUINT, Tween.EASE_IN)
	tween.start();
	
	var lastdistance = 0;
	while nudge_values[index] != targetdistance:
		var delta = nudge_values[index] - lastdistance;
		lastdistance += delta;
		reel.move(delta);
		yield(get_tree(), "physics_frame");
		
	yield(tween,"tween_all_completed");

	var delta = abs(targetdistance) - abs(lastdistance);
	delta *= sign(targetdistance);
	lastdistance += delta;
	reel.move(delta);
	yield(get_tree(), "physics_frame");
		
	for tile in reel.visible_tiles:
		tile.show_spine_sprite();
	
	tween.queue_free();
	nudge_values[index] = 0;
	reel.spinning = false;
	emit_signal("nudgeend");
	
	var fx = nudgefx_scene.instance();
	add_child(fx);
	if(sign(targetdistance) > 0):
		#fx.scale = Vector2(1, -1);
		fx.global_position = reel.to_global(Vector2(0, 790));
	else:
		fx.global_position = reel.to_global(Vector2(0, -70));
	yield(get_tree().create_timer(1.0), "timeout")
	fx.queue_free();
