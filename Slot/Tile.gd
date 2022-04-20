extends Node2D
class_name Tile

enum AnimationType { SPINE, TIMELINE };

#const TileData = preload("TileData.gd"); #? what is the purpose of this

export (float) var blur : float setget _setblur;
export (Vector2) var scale_multiplier : Vector2 = Vector2.ONE;

signal spinespriteshown
signal imageshown

signal ondiscard (tile, pos); #? is this used and for what

#var reel;
#var data;
var speed: int;
#var tiledesc : TileDescription;
var _invisible_tile: int = 0
var _description: TileDescription
var _id = 0;

#var speed = 0;

func _ready():
	_invisible_tile = Globals.singletons["Slot"].invisible_tile;
	$Image.material = $Image.material.duplicate();
	#Globals.singletons["AssetLoader"].connect("tiles_generated", self, "update_tex", [], CONNECT_ONESHOT)

#func init():
	#connect("visibility_changed", self, "_on_visibility_changed");
#	reel.connect("onstartspin", self, "reel_startspin");
#	reel.connect("onstoppinganim", self, "reel_stopping");
#	reel.connect("onstopped", self, "reel_stopped");

func getTilesWithId(tiles, id):
	var filteredTiles = [];
	for tile in tiles:
		if (tile.id == abs(id)):
			filteredTiles.append(tile);

	if (len(filteredTiles) == 0):
		push_error("no tile with id" + id as String);
		return tiles;

	return filteredTiles;
	
# setting the actual rendering stuff
#func setTileData(data):
#	print("Rename setTileData");
#	set_tile_data(data);

func set_tile(id, initial_position):
	# there could be more than one tile for the same tile id, though most of the time is one
	var posibleTiles = getTilesWithId(Globals.singletons["AssetLoader"].tiles, abs(id))
	var variant  = randi() % len(posibleTiles);
	_description = posibleTiles[variant];
	_id = id;

	position = initial_position 

	for child in get_children():
		_setScale(child);

#	if(self.data.feature != null && is_instance_valid(self.data.feature)): 
#		self.data.feature.init(self);

func _setScale(element):
	pass;
#	element.scale = self.tiledesc.tile_scale * scale_multiplier;
#	element.position = self.tiledesc.tile_offset;
		
func _setblur(val):
	if(_id == _invisible_tile): return;
	blur = val;
	$Image.material.set_shader_param( "dir", Vector2(0.0, blur));
	$Image.material.set_shader_param( "quality", int(blur)/15);
	
func get_spine():
	return $SpineSprite;
	
func reel_stopped(index):
	pass

#func show_spine_sprite():
#	_setScale($SpineSprite);
#	if(underneath_fat_tile): 
#		$SpineSprite.visible = false;
#		$Image.visible = false;
#	else:
#		$SpineSprite.position = self.tiledesc.image_offset;
##		$SpineSprite.position.y += image_offset * reel.tileDistance;
#		$SpineSprite.set_new_state_data(self.tiledesc.spine_data);
#		$SpineSprite.visible = true;
#		$SpineSprite.visible = false;
#		yield(VisualServer,"frame_post_draw");
#		$SpineSprite.visible = true;
#		$Image.visible = false;
#		emit_signal("spinespriteshown");

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
		
#########################################################################
func play_animation(name, type = AnimationType.SPINE):
	if (type == AnimationType.SPINE):
		print("I am playing spine animation....");
		return;
	
	if (type == AnimationType.TIMELINE):
		$AnimationPlayer.play(name);
		return;

	print("I don't know what type of animation top play....");
	
	
func show_image():
	if (_description.id == _invisible_tile):
		$Image.visible = false;
		emit_signal("imageshown");
		return;


	$Image.texture = load("res://Textures/test-tiles/tile"+ _description.id as String + ".png");
	
	var direction = sign(_id);
	var x = $Image.texture.get_width() / _description.size_x if _description.size_x > 1 else 0;
	var y = $Image.texture.get_height() / _description.size_y if _description.size_y > 1 else 0;

	$Image.offset.x = x;
	$Image.offset.y = -direction * y;
	$SpineSprite.visible = false;
	$Image.visible = true;
	
	
	emit_signal("imageshown");

func update_position(pos):
	position.x += pos.x;
	position.y += pos.y;
	
	return position;
