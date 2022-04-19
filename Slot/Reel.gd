extends Node2D
class_name Reel
const TileData = preload("TileData.gd")

export (float) var blurMultiplier : float;
export (float) var bluramount : float setget set_bluramount;
export (float) var topOffset : float = 0;
export (float) var spinPosition : float = 0;
export (float) var spinPositionOffset : float = 0;
export (int) var spinPositionNormal : int = 0;
export (float) var spinSpeed : float = 10;
export (float) var spinSpeedMultiplier : float = 0;
export (float) var tileDistance : float = 150;
export (int) var topTileCount : int = 3;
export (int) var visibleTileCount : int = 3;
export (int) var bottomTileCount : int = 3;
export (int) var stopExtraDistance : int = 5;
export (Array) var targetData : Array;
export (PackedScene) var tileScene;

export (bool) var auto_arange = true;
export (Vector2) var tile_size = Vector2.ZERO;

signal onstartspin;
signal onstopping;
signal onstoppinganim;
signal onstopped;

var slot;

#var totalTileCount : int;
#var queueData = [];
#var currentTiles = [];
var tiles = {};
#var visible_tiles = [];

var _buffer= []; 
var _position = 0;
var _start_position = 0;
var _tiles_count = 0;

var _posible_tiles = [];
var _spinning: bool = false
var _stopping: bool = false;

var _initial_speed = 0;
var _speed = _initial_speed;
var _acceleration = 10;
var _max_speed = 20;

#var spinning : bool = false;
#var stopped : bool = true;
#var stopping : bool = false;

var index : int = 0;
#var additional_stop_distance : int = 0;
#var stop_tile_offset_top : Array;
#var stop_tile_offset_bottom : Array;

#var _spinPositionNormal : int = 0;
#var _spinPositionTarget : float = 0;

func get_tile_at(y):
	return tiles[topTileCount+y];

	
func set_bluramount(val):
#	for tile in currentTiles: tile.blur = val * blurMultiplier;
	pass

func _start_spin_anim_end():
	pass

#func _generate_random_tiledata():
#	return TileData.new(slot.availableTiles[randi() % len(slot.availableTiles)]);

#####################################################################
func initialize(index, posibleTiles):
	_tiles_count = topTileCount + visibleTileCount + bottomTileCount;
	self.index = index;
	self._position = visibleTileCount + bottomTileCount - 1;
	self._start_position = self._position;
	self._posible_tiles = posibleTiles;
	
	if (auto_arange):
		position.x = index * tile_size.x;
	
	for i in range(_tiles_count):
		var tile = _generate_tile_at(i);
		tiles[i] = tile;
		$TileContainer.add_child(tile);

func assign_tiles(serverIds):
	var ids = _reverse_data(serverIds);
	var top = _generate_random_data(topTileCount);
	var bottom = _generate_random_data(bottomTileCount);
	var data = bottom + ids + top;
	var tiles = $TileContainer.get_children();
	
	_add_to_buffer(data);
	for i in range(tiles.size()): 
		_set_tile(tiles[i], i - topTileCount);

func start_spin():
	_spinning = true;
	_start_position = _position;
	
#	$AnimationPlayer.play("ReelSpinStartAnimation");

func stop_spin(serverData):
	var data = _reverse_data(serverData);
	var top = _generate_random_data(topTileCount);
	
	_add_to_buffer(data + top);
	_stopping = true;

func _set_tile(tile, index1 = 0, offest = Vector2.ZERO):
	var pos = int(_position) - index1;
	var id = 1 if pos >= _buffer.size() else _buffer[pos];

	tile.position.x = tile_size.x / 2 + offest.x;
	tile.position.y = tile_size.y / 2 + (index1) * tile_size.y + offest.y;

	tile.set_tile_data(TileData.new(id));
	tile.show_image();
	
	
func _process(delta):
	if (!_spinning): return;
	_speed = min(_max_speed, _speed + delta * _acceleration); # tiles per second
	var max_position = _buffer.size() - topTileCount - 1;
	var is_over = _stopping && _position >= max_position;
	if (_spinning && !is_over):
		_position = min(max_position, _position + delta * _speed);
		
#	print(_position, ' | ', max_position, " | ", _stopping, " | ", _spinning);
	if (_spinning && !_stopping && _position >= max_position):
		_add_to_buffer(_generate_random_data(int(topTileCount)));

	_moveTo(_position);
	if (is_over): _on_stoppped()


func _on_stoppped():
	_spinning = false;
	_stopping = false;
	_speed = _initial_speed;
	emit_signal("onstopped", self.index);

func _moveTo(pos):
	var reel_hight = tile_size.y * (visibleTileCount + bottomTileCount);
	var limit = reel_hight - tile_size.y / 2;
	var tiles = $TileContainer.get_children();
	var distance = (pos - _start_position) * tile_size.y;

	_start_position = pos; # TODO rename to last_position
	
	for i in range(tiles.size()):
#		tiles[i].position.x = tile_size.x / 2;
		tiles[i].position.y += distance;
		if (tiles[i].position.y >= limit):
#			tiles[i].position.y = tile_size.y / 2 - topTileCount * tile_size.y + (tiles[i].position.y - limit);
			_set_tile(tiles[i], -topTileCount, Vector2(0, tiles[i].position.y - limit));

func _add_to_buffer(ids):
	_buffer = _buffer + ids;
#
#	if(self.index == 0):
#		print("the buffer", _buffer)

func _generate_random_data(size):
	var data = [];
	var length = len(_posible_tiles);
	#TODO use some -1 or something for unvisible tile
	for i in range(size): 
		var id = 0 if length == 0 else _posible_tiles[randi() % length];
		data.append(id);
		
	return data;
	
func _generate_tile_at(position):
	var tile = tileScene.instance();
	tile.reel = self; #TODO do not pass the parent to the child
	tile.reelPosition = position * tileDistance; #? this is probably the tile size
	tile.reelIndex = index;
	tile.tileIndex = position;
	tile.init(); #TODO pass all of the upper as paramethers and check if they are really need it.
	
	return tile;

func _reverse_data(data):
	var reversed = data.duplicate();
	reversed.invert();
	
	return reversed;
