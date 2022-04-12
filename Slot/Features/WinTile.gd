extends Node
class_name WinTile

var tile : Tile;
var original_parent;
var original_transform;
var original_pos;
var animation_counter = -1;
var is_fat_tile = false;
var is_fat_tile_fully_shown = false;

func init():
	is_fat_tile = tile.fat_tile != null;
	if(is_fat_tile): tile = tile.fat_tile;
	
	original_pos = tile.position;
	original_transform = tile.transform;
	
	if(tile.is_set_as_toplevel()): return;

	animation_counter = tile.tiledesc.spine_win_anim_animation_repeat;

	if(!tile.get_spine().visible):
		tile.show_spine_sprite();
		#yield(tile, "spinespriteshown");
		if(is_fat_tile):
			is_fat_tile_fully_shown = tile.tiles_below == tile.tiledesc.size_y;
			if(is_fat_tile_fully_shown):
				tile.z_index = 1;
				tile.set_as_toplevel(true);
		else:
			tile.z_index = 1;
			tile.set_as_toplevel(true);

		if(tile.tiledesc.spine_win_anim != ""):
			tile.get_spine().play_anim(tile.tiledesc.spine_win_anim, true, null, false);
		else:
			tile.get_spine().play_anim("popup", true, null, false);
		if(animation_counter > -1): 
			tile.get_spine().connect("animation_complete", self, "animation_complete")
			
	if(is_fat_tile && !is_fat_tile_fully_shown): return;
	tile.transform = tile.get_parent().global_transform * original_transform;
	tile.global_position = tile.get_parent().to_global(original_pos);
	
func reset():
	if(tile.z_index == 0): return; #Already reset
	if(tile.get_spine().is_connected("animation_complete", self, "animation_complete")):
		tile.get_spine().disconnect("animation_complete", self, "animation_complete")
			
	tile.set_as_toplevel(false);
	tile.transform = original_transform;
	tile.global_position = tile.get_parent().to_global(original_pos);
	tile.z_index = 0;
	tile.show_image();
	
func _process(_delta):
	if(is_fat_tile && !is_fat_tile_fully_shown): return;
	tile.transform = tile.get_parent().global_transform * original_transform;
	tile.global_position = tile.get_parent().to_global(original_pos);

func animation_complete(animation_state, track_entry, event):
	if(animation_counter > 0):
		animation_counter -= 1;
		if(animation_counter == 0):
			tile.get_spine().disconnect("animation_complete", self, "animation_complete")
			if(tile.tiledesc.spine_idle_anim != ""):
				tile.get_spine().play_anim(tile.tiledesc.spine_idle_anim, true, null, false);
			else:
				tile.get_spine().play_anim("idle", true, null, false);
				
func get_class(): return "WinTile"
