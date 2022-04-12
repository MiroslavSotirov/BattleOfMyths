extends Node

export (int) var anticipation_duration = 20;
export (Vector2) var anticipation_offset;
export (PackedScene) var anticipation_scene;
export (Color) var darken_color;
export (Array) var tiles; # array of TileDescription resources

var anticipation : Dictionary = {};
var reel_anticipations : Dictionary = {};
var activating_reel : int = 0;
var tweens : Dictionary = {};

func _ready():
	Globals.register_singleton("Anticipation", self);
	yield(Globals, "allready")
	Globals.singletons["Slot"].connect("apply_tile_features", self, "apply_to_tiles");
	yield(get_tree(), "idle_frame");

	for reel in Globals.singletons["Slot"].reels:
		reel.connect("onstopping", self, "on_reel_stopping", [reel]);
		reel.connect("onstopped", self, "on_reel_stopped", [reel]);
		
func check_reel(reel_data, cfg, count):
	var mininum = cfg.max_count - 1;
	var maximum = cfg.max_count;
	for i in reel_data.size():
		var tile = int (reel_data[i]);

		if (tile == cfg.id):
			count[tile] = count[tile] + 1 if count.has(tile) else 1;

	return count.has(cfg.id) && count[cfg.id] >= mininum && count[cfg.id] < maximum;

func check_for_anticipation(cfgs, data):
	var count = {};
	var reels = [];
	var tiles = [];
	
	for i in data.size():
		reels.append(false);
		
		for j in cfgs.size():
			var cfg = cfgs[j]
			if (cfg == null): continue;
			elif (i == 0):
				reels[i] = false
			else:
				var hasAnticipation = (check_reel(data[i - 1], cfg, count) && cfg.posible_reels.has(i));
				reels[i] = reels[i] || hasAnticipation;
				if (hasAnticipation):
					tiles.append(cfg.id)
	
	return {"reels": reels, "tiles": tiles};

func apply_to_tiles(spindata, reeldata):
#	target_tiles.clear();
	anticipation.clear();
	tweens.clear();
	reel_anticipations.clear();

	anticipation = check_for_anticipation(tiles, spindata.view);
	
	var reels = Globals.singletons["Slot"].reels;
	for i in len(reels):
		var extra_duration = anticipation_duration if anticipation.reels[i] else 0
		if (i == 0):
			reels[i].additional_stop_distance = extra_duration;
		else:
			reels[i].additional_stop_distance = reels[i - 1].additional_stop_distance + extra_duration;


func on_reel_stopping(reel):
	pass

func on_reel_stopped(reel):
	if ("reels" in anticipation && !anticipation.reels.has(true)): return;
	var last_reel = Globals.singletons["Slot"].reels.size() - 1;

	if(reel.index == activating_reel): 
		#Anticipation START
		Globals.singletons["Game"].anticipation_start();
		Globals.singletons["Audio"].fade("Anticipation", 1, 1, 0);
		Globals.singletons["Audio"].loop("Anticipation");
		if("reels" in anticipation):
			for i in len(anticipation.reels):
				if (anticipation.reels[i]):
					var ant = anticipation_scene.instance();
					Globals.singletons["Slot"].reels[i].add_child(ant);
					ant.position = anticipation_offset;
					reel_anticipations[i] = ant;
				else:
					darken_reel(i);

	elif(reel_anticipations.has(reel.index)):
		reel_anticipations[reel.index].get_node("AnimationPlayer").play("hide");
		darken_reel(reel.index);
		if(reel.index == last_reel):
			Globals.singletons["Audio"].fade("Anticipation", 1, 0, 0.25);
			
func darken_reel(i):
	if(!tweens.has(i)):
		tweens[i] = Tween.new();
		add_child(tweens[i]);
	
	for tile in Globals.singletons["Slot"].reels[i].tiles.values():
		if (anticipation.tiles.has(int(tile.data.id))): continue;
		tweens[i].interpolate_property(tile, "modulate",
			Color.white, darken_color, 0.5,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT);
			
	tweens[i].start();
	
func lighten_reels():
	yield(get_tree(),"idle_frame");
	if(len(tweens.keys()) == 0): return false;
	for i in tweens.keys():
		lighten_reel(i);
	Globals.singletons["Game"].anticipation_end();
	
func lighten_reel(i):
	for tile in Globals.singletons["Slot"].reels[i].tiles.values():
		tweens[i].interpolate_property(tile, "modulate",
			tile.modulate, Color.white, 0.5,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT);
	tweens[i].start();
	tweens[i].connect("tween_all_completed", tweens[i], "queue_free");
