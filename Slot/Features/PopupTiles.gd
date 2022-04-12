extends Node

var to_pop_tiles : Array = [];
var pop_tiles : Array = [];
var popup_tile_count = 0;
var remaining_tile_count = 0;
var skipped : bool = false;

signal popuptilesend;

func _ready():
	Globals.register_singleton("PopupTiles", self);
	Globals.connect("skip", self, "on_try_skip");
	yield(Globals, "allready")
	Globals.singletons["Slot"].connect("onstartspin", self, "reset");
	
func reset():
	to_pop_tiles.clear();
	pop_tiles.clear();
	popup_tile_count = 0;
	remaining_tile_count = 0;
	skipped = false;
	
func get_tile_at(x,y):
	for tile in pop_tiles:
		if(tile.tileX == x && tile.tileY == y): return tile;
	return null;
	
func get_tiles_id(id):
	var arr = [];
	for tile in pop_tiles:
		if(tile.id == id): arr.append(tile);
	return arr;

func add_popup_tile(tile : Tile):
	pop_tiles.append(tile);
	if(tile.tiledesc.popup_z_change):
		tile.z_index = 1;
	if(tile.tiledesc.popup_wait):
		remaining_tile_count += 1;
		to_pop_tiles.append(tile);
		if(!tile.get_spine().is_connected("animation_complete", self, "popup_complete")):
			tile.get_spine().connect("animation_complete", self, "popup_complete", [tile], CONNECT_ONESHOT);

func unpop_all():
	call_deferred("_unpop_all")
	
func _unpop_all():
	for tile in pop_tiles:
		tile.z_index = 0;
		if(tile.get_spine().is_connected("animation_complete", self, "popup_complete")):
			tile.get_spine().disconnect("animation_complete", self, "popup_complete");

func clear_all():
	for tile in pop_tiles:
		tile.show_image();

func popup_complete(animation_state: Object, track_entry: Object, event: Object, tile : Tile):
	#prints(tile.reelIndex, tile.tileIndex, "Popped", remaining_tile_count);
	remaining_tile_count -= 1;
	
	if(remaining_tile_count == 0):
		emit_signal("popuptilesend");
		
	to_pop_tiles.erase(tile);
	
	if(tile.tiledesc.spine_idle_anim != ""):
		tile.get_spine().play_anim(tile.tiledesc.spine_idle_anim, true);

func on_try_skip():
	skipped = true;
	for tile in to_pop_tiles:
		tile.get_spine().set_timescale(2.0, false);
