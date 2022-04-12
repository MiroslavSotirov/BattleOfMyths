extends Node
class_name BarsFillFx

export (PackedScene) var greenfxscene;
export (PackedScene) var bluefxscene;
export (Vector2) var offset;
var skipped : bool = false;
signal animation_end;

func _ready():
	Globals.register_singleton("BarsFillFx", self);
	Globals.connect("skip", self, "on_try_skip");
	
func activate():
	$Tween.remove_all();
	var has_tiles = false;
	if(!("features" in Globals.singletons["Networking"].lastround)): return false;
	for feature in Globals.singletons["Networking"].lastround.features:
		if(feature.type != "FatTile"): continue;
		var data = feature.data;
		if(data.y != 0): continue
		var tile = Globals.singletons["Slot"].get_tile_at(data.x, data.y);
		if(tile.fat_tile): tile = tile.fat_tile;
		if(data.tileid == 8):
			create_greenfx(tile); 
			has_tiles = true;
		if(data.tileid == 9):
			create_bluefx(tile);
			has_tiles = true;
	if(has_tiles):
		$Tween.playback_speed = 1.0;
		$Tween.start(); 
		skipped = false;
		send_event();
	return has_tiles;
	
func send_event():
	yield($Tween, "tween_completed");
	emit_signal("animation_end");

func create_greenfx(tile):
	tile.get_spine().play_anim_then_loop("popup", "idle");
	Globals.singletons["Audio"].play("CharacterAppear");
	var fx = greenfxscene.instance();
	add_child(fx);
	fx.global_position = tile.global_position;
	animate_fx(fx, Globals.singletons["BarGreen"], "GreenBar");

func create_bluefx(tile):

	tile.get_spine().play_anim_then_loop("popup", "idle");
	Globals.singletons["Audio"].play("CharacterAppear");
	var fx = bluefxscene.instance();
	add_child(fx);
	fx.global_position = tile.global_position;
	animate_fx(fx, Globals.singletons["BarBlue"], "BlueBar");
	
func animate_fx(fx, target, sound):
	Globals.singletons["Audio"].play_after("Magic", 800, 0.6);
	var pos = target.get_bar_top_pos() + offset;
	$Tween.interpolate_property(fx, "global_position",
		fx.global_position, pos, 1.5,
		Tween.TRANS_QUART, Tween.EASE_IN_OUT,0.25);
	yield($Tween, "tween_all_completed");
	$Tween.playback_speed = 1.0;
	skipped = true;
	fx.get_node("Wiggler/Trail").emit = false;
	fx.get_node("HitFx").emitting = true;
	fx.get_node("HitFx2").emitting = true;
	$Tween.interpolate_property(fx.get_node("Wiggler"), "modulate",
		Color.white, Color.black, 0.25,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT);
	$Tween.start();
	Globals.singletons["Audio"].play(sound);
	yield(get_tree().create_timer(1.0), "timeout");
	fx.queue_free();

func on_try_skip():
	if(skipped): return;
	skipped = true;
	$Tween.playback_speed = 3.0;
