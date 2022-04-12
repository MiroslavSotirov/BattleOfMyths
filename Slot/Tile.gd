extends Node2D
class_name Tile

const TileData = preload("TileData.gd"); #? what is the purpose of this
export (float) var reelPosition : float;
export (int) var reelIndex : int;
export (int) var tileIndex : int;
export (float) var blur : float setget _setblur;
export (Vector2) var scale_multiplier : Vector2 = Vector2.ONE;

signal spinespriteshown
signal imageshown

signal ondiscard (tile, pos); #? is this used and for what

var underneath_fat_tile : bool;
var fat_tile : Tile;
var image_offset : int = 0;
var reel;
var data;
var tiledesc : TileDescription;
var outside_screen := false;
var tiles_below := 1;
var tiles_above := 1;

func _ready():
	$Image.material = $Image.material.duplicate();
	#Globals.singletons["AssetLoader"].connect("tiles_generated", self, "update_tex", [], CONNECT_ONESHOT)

func init():
	#connect("visibility_changed", self, "_on_visibility_changed");
	reel.connect("onstartspin", self, "reel_startspin");
	reel.connect("onstoppinganim", self, "reel_stopping");
	reel.connect("onstopped", self, "reel_stopped");

func getTilesWithId(tiles, id):
	var filteredTiles = [];
	for tile in tiles:
		if (tile.id == id):
			filteredTiles.append(tile);

	if (len(filteredTiles) == 0):
		push_error("no tile with id" + id as String);
		return tiles;

	return filteredTiles;
	
# setting the actual rendering stuff
func setTileData(data):
	print("Rename setTileData");
	set_tile_data(data);

func set_tile_data(data):
	self.data = data;
	if(self.data == null): return
	
	# there could be more than one tile for the same tile id, though most of the time is one
	var posibleTiles = getTilesWithId(Globals.singletons["AssetLoader"].tiles, self.data.id)
	self.data.variant  = self.data.variant if self.data.variant != -1 else randi() % len(posibleTiles);
	self.tiledesc = posibleTiles[self.data.variant];

	if(self.data.feature != null && is_instance_valid(self.data.feature)): 
		self.data.feature.init(self);

	for child in get_children():
		_setScale(child);

	
func _setScale(element):
	pass;
#	element.scale = self.tiledesc.tile_scale * scale_multiplier;
#	element.position = self.tiledesc.tile_offset;
		
func _setblur(val):
	if(self.data == null): return;
	blur = val;
	$Image.material.set_shader_param( "dir", Vector2(0.0, blur));
	$Image.material.set_shader_param( "quality", int(blur)/15);
	
func get_spine():
	return $SpineSprite;
	
func check_underneath_fat_tile():
	if(tiledesc.size_y > 1):
		tiles_above = 1;
		while(reel.tiles.has(tileIndex-tiles_above)):
			if(reel.tiles[tileIndex-tiles_above].data.id == data.id): tiles_above += 1;
			else: break;
		
		tiles_below = 1;
		while(reel.tiles.has(tileIndex+tiles_below)):
			if(reel.tiles[tileIndex+tiles_below].data.id == data.id): tiles_below += 1;
			else: break;			

		if(tiles_above <= 1): #We are on the top. Draw!
			fat_tile = self;
			underneath_fat_tile = false;
			if(tiles_below < tiledesc.size_y):
				image_offset = tiles_below - tiledesc.size_y + tileIndex;
			else:
				image_offset = 0;
		else: 
			fat_tile = reel.tiles[tileIndex-tiles_above+1];
			underneath_fat_tile = true;
			image_offset = 0;
	else:
		fat_tile = null;
		underneath_fat_tile = false;
		image_offset = 0;
	
func reel_startspin():
	# TODO this is probably not need it
	if(underneath_fat_tile):
		$SpineSprite.visible = false;
		$Image.visible = false;
	else:
		$Image.visible = true;
		$SpineSprite.visible = false;
		$Image.position = tiledesc.image_offset;
		$Image.position.y += image_offset * reel.tileDistance;
	
func reel_stopping(index):
	yield(get_tree(), "idle_frame");
	#if(underneath_fat_tile): return;
	if(tiledesc.popup && !underneath_fat_tile):				
		Globals.singletons["PopupTiles"].add_popup_tile(self);
		show_spine_sprite();
		yield(self, "spinespriteshown");
		$SpineSprite.play_anim_then_loop(tiledesc.spine_popup_anim, tiledesc.spine_idle_anim);
		$SpineSprite.set_timescale(tiledesc.spine_popup_anim_speed, false);
		if(tiledesc.popup_sfx != ""):
			Globals.singletons["Audio"].play(tiledesc.popup_sfx);
	
func reel_stopped(index):
	pass

func show_spine_sprite():
	_setScale($SpineSprite);
	if(underneath_fat_tile): 
		$SpineSprite.visible = false;
		$Image.visible = false;
	else:
		$SpineSprite.position = self.tiledesc.image_offset;
		$SpineSprite.position.y += image_offset * reel.tileDistance;
		$SpineSprite.set_new_state_data(self.tiledesc.spine_data);
		$SpineSprite.visible = true;
		$SpineSprite.visible = false;
		yield(VisualServer,"frame_post_draw");
		$SpineSprite.visible = true;
		$Image.visible = false;
		emit_signal("spinespriteshown");

#func show_image():
#	_setScale($Image);
#	if(underneath_fat_tile):
#		$Image.visible = false;
#		$SpineSprite.visible = false;
#	else:
#		$SpineSprite.visible = false;
#		$Image.visible = true;
#		$Image.texture = self.tiledesc.static_image;
#		$Image.position = self.tiledesc.image_offset;
#		$Image.position.y += image_offset * reel.tileDistance;
#		emit_signal("imageshown");
		
func update_position():
	var delta = fmod(reel.spinPosition, reel.tileDistance);
	position.y = reelPosition + delta + reel.spinPositionOffset + reel.topOffset;
	if(image_offset != 0 && $Image.visible):
		$Image.position.y = \
			self.tiledesc.image_offset.y \
			+ image_offset * reel.tileDistance \
			+ delta;
	
#func _process(_delta):
#	if(reel.spinning): update_position();
	
#########################################################################
			
func show_image():
	_setScale($Image);
	$SpineSprite.visible = false;
	$Image.visible = true;
	$Image.texture = load("res://Textures/test-tiles/tile"+ tiledesc.id as String + ".png");
#	$Image.texture = self.tiledesc.static_image;
#	$Image.position = tiledesc.image_offset;
#	print('width: ', $Image.texture.get_width());
	$Image.position.y += image_offset * reel.tileDistance;
	emit_signal("imageshown");
