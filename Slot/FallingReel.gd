extends Node2D
class_name Reel
#const TileData = preload("TileData.gd")

export (float) var blurMultiplier : float;
export (float) var bluramount : float setget set_bluramount;
export (int) var top_tiles_count : int = 3;
export (int) var visible_tiles_count : int = 3;
export (int) var bottom_tiles_count : int = 3;
 
export (Array) var targetData : Array;
export (PackedScene) var tileScene;

export (bool) var auto_arange = true;
export (Vector2) var tile_size = Vector2.ZERO;

signal onstartspin;
signal onstopping;
signal onstoppinganim;
signal onstopped;
signal oncleared;

var tiles: Array setget , _get_tiles;

var _buffer = []; 
var _position = 0;
var _start_position = 0;
var _tiles_count = 0;
var _visible_tiles: Array setget , _get_visible_tiles;

var _posible_tiles = [];
var _spinning: bool = false
var _stopping: bool = false;

var _initial_speed = 0;
var _speed = _initial_speed;
var _acceleration = 120;
var _max_speed = 100;

var spinning : bool = false;
var stopped : bool = true;
var stopping : bool = false;

var index : int = 0;

var _time = 0;
################ FALLING TILES ################
var _filling: bool = false; # true when the screen is being filled with the new tiles /the spin result/
###############################################

func get_tile_at(y):
	return self.tiles[top_tiles_count + y];

	
func set_bluramount(val):
#	for tile in currentTiles: tile.blur = val * blurMultiplier;
	pass

func _start_spin_anim_end():
	pass

func initialize(index, posibleTiles):
	_tiles_count = top_tiles_count + visible_tiles_count + bottom_tiles_count;
	self.index = index;
	self._position = visible_tiles_count + bottom_tiles_count - 1;
	self._start_position = self._position;
	self._posible_tiles = posibleTiles;

	if (auto_arange):
		position.x = index * tile_size.x;
	
	for i in range(_tiles_count):
		var tile = tileScene.instance();
		$TileContainer.add_child(tile);

func set_initial_screen(server_data):
	var ids = _reverse_data(server_data);
	var top = _generate_random_data(top_tiles_count);
	var bottom = _generate_random_data(bottom_tiles_count);
	var data = bottom + ids + top;
	
	_add_to_buffer(data);

	for i in range(self.tiles.size()): 
		_set_tile(self.tiles[i], i - top_tiles_count);

func start_spin():
	_spinning = true;
	_start_position = _position;

#	$AnimationPlayer.play("ReelSpinStartAnimation");
	
func stop_spin(server_data):
	var data = _reverse_data(server_data);
	var top = _generate_random_data(top_tiles_count);
	
	_add_to_buffer(data + top);

	if (!_filling): yield(self, "oncleared");

	_stopping = true;
	_position = _buffer.size() - top_tiles_count - 1;

	for i in range(self._visible_tiles.size()): 
		_set_tile(self._visible_tiles[i], i, Vector2(0, (-visible_tiles_count - 2) * tile_size.y));
	
	call_deferred("_fill");
	

func _set_tile (tile, tile_index = 0, offest = Vector2.ZERO):
	var pos = int(_position) - tile_index;
	var id = 1 if pos >= _buffer.size() else _buffer[pos];

	var x = tile_size.x / 2 + offest.x;
	var y = tile_size.y / 2 + (tile_index) * tile_size.y + offest.y;

	tile.set_tile(id, Vector2(x, y));
	tile.show_image();
	
func _process(delta):
	if (!_spinning): return;
	
	_time = _time + delta;
	var slot_egde = tile_size.y * (visible_tiles_count + 1 + 2) - tile_size.y / 2;
	var delay_per_tile = 0.05;
	var fallen_tiles = 0;
	
	for i in range(visible_tiles_count):
		if ((visible_tiles_count - i) * delay_per_tile > _time): continue;
		
		var tile = self.tiles[i + top_tiles_count];
		var limit = i * tile_size.y + tile_size.y / 2 if _filling else slot_egde;
		tile.speed = min(_max_speed, tile.speed + delta * _acceleration);
		tile.update_position(Vector2(0, min(limit - tile.position.y, tile.speed)));
		
		if (tile.position.y >= limit):
			if (_filling): tile.play_animation("drop", Tile.AnimationType.TIMELINE)
			fallen_tiles += 1;

	if (fallen_tiles == visible_tiles_count):
		_on_clear();

func _on_stoppped():
	_spinning = false;
	_stopping = false;
	_time = 0;
	_speed = _initial_speed;

	for tile in self.tiles:
		tile.speed = _initial_speed;

	emit_signal("onstopped", self.index);

func _moveTo(pos):
	var reel_hight = tile_size.y * (visible_tiles_count + bottom_tiles_count);
	var limit = reel_hight - tile_size.y / 2;
	var tiles = self.tiles;
	var distance = (pos - _start_position) * tile_size.y;

	_start_position = pos; # TODO rename to last_position
	
	for i in range(tiles.size()):
		var new_pos = tiles[i].update_position(Vector2(0, distance));
		if (new_pos.y >= limit):
			_set_tile(tiles[i], -top_tiles_count, Vector2(0, tiles[i].position.y - limit));

func _add_to_buffer(ids):
	_buffer = _buffer + ids;

func _generate_random_data(size):
	var data = [];
	var length = len(_posible_tiles);
	for i in range(size): 
		var id = 1 if length == 0 else _posible_tiles[randi() % length];
		data.append(id);

	return data;

func _reverse_data(data):
	var reversed = data.duplicate();
	reversed.invert();
	
	return reversed;
	
func _get_tiles():
	return $TileContainer.get_children()
	
func _get_visible_tiles():
	return self.tiles.slice(top_tiles_count, visible_tiles_count + top_tiles_count - 1);
	
################ FALLING TILES ################
func _fill():
	_filling = true;
	
func _on_clear():
	if (!_filling):
		_time = 0;
		emit_signal("oncleared", self.index);
	else:
		_filling = false;
		_on_stoppped();
		
