extends Node2D
class_name Tile

enum AnimationType { SPINE, TIMELINE };

#const TileData = preload("TileData.gd"); #? what is the purpose of this

export (float) var blur : float setget _setblur;
export (Vector2) var scale_multiplier : Vector2 = Vector2.ONE;

signal spinespriteshown
signal imageshown
signal hide_end
signal animation_finished(name);

var speed: int;

var _invisible_tile: int = 0
var _description: TileDescription
var id = 0;
var _hidden = false;

func _ready():
	_invisible_tile = Globals.singletons["Slot"].invisible_tile;
	$AnimationPlayer.connect("animation_finished", self, "_on_animation_finished");
	$SpineSprite.connect("animation_complete", self, "_on_animation_finished");
	$Image.material = $Image.material.duplicate();
	#Globals.singletons["AssetLoader"].connect("tiles_generated", self, "update_tex", [], CONNECT_ONESHOT)

func set_tile(_id, initial_position):
	# there could be more than one tile for the same tile id, though most of the time is one
	var posibleTiles = _get_tiles_with_id(Globals.tiles, abs(_id))
	var variant  = randi() % len(posibleTiles);

	_description = posibleTiles[variant];
	$SpineSprite.scale.x = _description.tile_scale.x;
	$SpineSprite.scale.y = _description.tile_scale.y;
	$Image.scale.x = _description.tile_scale.x;
	$Image.scale.y = _description.tile_scale.y;
	if (abs(_id) != abs(id)): 
		$SpineSprite.set_new_state_data(_description.spine_data);
	else:
		#TODO check for better approach
		$SpineSprite.reset_pose();

		
	id = _id;
	position = initial_position 
	
#	yield(get_tree(),"idle_frame");
	var direction = sign(id);
	var tile_width = _description.image_size.x / _description.size_x;
	var tile_height = _description.image_size.y / _description.size_y;

	var x = tile_width / 2 * (_description.size_x - 1) if _description.size_x > 1 else 0;
	var y = tile_height / 2 * (_description.size_y - 1) if _description.size_y > 1 else 0;

	$Image.offset.x = -direction * x;
	$Image.offset.y = -direction * y;
	$SpineSprite.position.x = (-direction * x) * _description.tile_scale.x;
	$SpineSprite.position.y = (-direction * y) * _description.tile_scale.y;
	
func get_spine():
	return $SpineSprite;

func hide(animationType = AnimationType.SPINE, animation = "hide", timescale=1.0):
	if (_hidden): return Promise.resolve();
	_hidden = true;
	play_animation(animationType, animation, false, timescale);
	return yield(self, "animation_finished");

func popup(animationType = AnimationType.SPINE, animation = "popup", loop = true):
	play_animation(animationType, animation, loop);
	return yield(self, "animation_finished");

func reel_stopped(index):
	pass

func show_spine_sprite():
	if ($SpineSprite.visible || _description.id == _invisible_tile): return;

	$SpineSprite.visible = false;
	yield(VisualServer,"frame_post_draw");
	$SpineSprite.visible = true;
	$Image.visible = false;

func spine_play_then_loop(anim, loopanim):
	show_spine_sprite();
	$SpineSprite.play_anim_then_loop(anim, loopanim)

#########################################################################
func play_animation(type = AnimationType.SPINE, name = null, loop = false, timescale_override = null, has_delay = true):
	if (_description.id == _invisible_tile):
		return call_deferred("_on_animation_finished", name);

	if (name == null):
		push_error("no animation name provied");
		return;

	if (type == AnimationType.SPINE ):
		print("I am playing spine animation.... ", name);
		show_spine_sprite();
		$SpineSprite.play_anim(name, loop, timescale_override, has_delay);
		return;
	
	if (type == AnimationType.TIMELINE && $AnimationPlayer.has_animation(name)):
		$AnimationPlayer.play(name);
		return;

	print("I don't know what type of animation top play.... ", name);
	return call_deferred("_on_animation_finished", name);
	
func _on_animation_finished(name, track = null, __ = null):
	if (track == null):
		emit_signal("animation_finished", name);
	else:
		var spine_anim_name = track.get_animation().get_anim_name();
		emit_signal("animation_finished", spine_anim_name);

func show_image():
	if (_description.id == _invisible_tile):
		$Image.visible = false;
		emit_signal("imageshown");
		return;
	
#	$Image.texture = load("res://Textures/test-tiles/tile"+ _description.id as String + ".png");
	$Image.texture = self._description.static_image;
	
#	$SpineSprite.visible = true;
#	$Image.visible = false;
	
	$SpineSprite.visible = false;
	$Image.visible = true;
	_hidden = false;
	
	emit_signal("imageshown");

func update_position(pos):
	position.x += pos.x;
	position.y += pos.y;
	
	return position;

func _setblur(val):
	if(id == _invisible_tile): return;
	blur = val;
	$Image.material.set_shader_param( "dir", Vector2(0.0, blur));
	$Image.material.set_shader_param( "quality", int(blur)/15);
	
func _get_tiles_with_id(tiles, id):
	var filteredTiles = [];
	for tile in tiles:
		if (tile.id == abs(id)):
			filteredTiles.append(tile);

	if (len(filteredTiles) == 0):
		push_error("no tile with id" + id as String);
		return tiles;

	return filteredTiles;
