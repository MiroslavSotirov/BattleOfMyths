extends Reel
class_name FallingReel
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
var is_spinning: bool setget , _get_is_spinning;

var _buffer = []; 
var _position = 0;
var _start_position = 0;
var _tiles_count = 0;
var _visible_tiles: Array setget , _get_visible_tiles;
var _removed_tiles = [];

var _posible_tiles = [];
var _spinning: bool = false
var _stopping: bool = false;
var _tiles_natural_positions = [];

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

	for i in range(visible_tiles_count):
		_tiles_natural_positions.append(Vector2(0, i * tile_size.y + tile_size.y / 2));

func set_initial_screen(server_data):
	var ids = _reverse_data(server_data);
	var top = _generate_random_data(top_tiles_count);
	var bottom = _generate_random_data(bottom_tiles_count);
	var data = bottom + ids + top;
	
	_add_to_buffer(data);

	for i in range(self.tiles.size()):
		_set_tile(self.tiles[i], i - top_tiles_count);

func shift():
	_spinning = true;
	_filling = true;
	_stopping = true;
	
func start_spin():
	for i in range(self.tiles.size()):
		_set_tile(self.tiles[i], i - top_tiles_count);

	_spinning = true;
	_start_position = _position;
	_removed_tiles = [];
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
	yield(self, "onstopped");

func add_tiles(data):
	if (_removed_tiles.size() == 0): return Promise.resolve();
	var new_tiles = _reverse_data(data.slice(0, _removed_tiles.size() - 1));

	_buffer = _buffer.slice(0, int(_position)) + _reverse_data(data.slice(0, _removed_tiles.size() - 1));
	var offsets = _get_tiles_offset(_reverse_data(_removed_tiles));
	for i in range(self._visible_tiles .size()):
		_set_tile(self._visible_tiles[i], i, offsets[i]);

	_removed_tiles = [];
	shift();
	yield(self, "onstopped");
	
func remove_tiles(indexes):
	indexes.sort();
	_removed_tiles = indexes;
	_buffer =  _remove_from_buffer(indexes);
	
	var promises = [];
	for index in indexes:
		var tile = self._visible_tiles[index];
		promises.push_back(tile.hide());

	yield(Promise.all(promises), "completed");

func _get_tiles_offset(removed_tiles):
	var offsets = [];
	for i in range(visible_tiles_count):
		offsets.append(Vector2(0, 0));

	for index in removed_tiles:
		for j in range(offsets.size()):
			var tile_position = _get_tile_pos(j , offsets[j]);
			var removed_tile_position = _get_tile_pos(index);
	
			if tile_position <= removed_tile_position:
				offsets[j].y = offsets[j].y - tile_size.y;
	
	return offsets;
	
func _get_tile_pos(index, offset = Vector2(0, 0), size = tile_size):
	var y = index * size.y + size.y / 2 + offset.y;
	
	return Vector2(0, y);

func _remove_from_buffer(indexes = []):
	if (indexes.size() == 0): return _buffer;
	
	var new_buffer = _buffer.duplicate();
	for index in indexes:
		new_buffer.remove(int(_position) - index);
	
	return new_buffer;

func _set_tile (tile, tile_index = 0, offest = Vector2.ZERO):
	var pos = int(_position) - tile_index;
	var id = Globals.singletons["Slot"].invisible_tile if pos >= _buffer.size() else _buffer[pos];
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
		var limit = _tiles_natural_positions[i].y if _filling else slot_egde;

		if (tile.position.y >= limit):
			_on_drop(tile, i);
			fallen_tiles += 1;
		else:
			tile.speed = min(_max_speed, tile.speed + delta * _acceleration);
			tile.update_position(Vector2(0, min(limit - tile.position.y, tile.speed)));

	if (fallen_tiles == visible_tiles_count):
		_on_clear();

func _on_drop(tile, i):
	if (_filling && tile.speed > 0): 
		tile.play_animation("drop", Tile.AnimationType.TIMELINE);
	tile.speed = _initial_speed;
	
func _on_stoppped():
	_spinning = false;
	_stopping = false;
	_time = 0;
#	_speed = _initial_speed;

#	TODO 0.5 is the duration of the drop animation
	yield(get_tree().create_timer(0.5), "timeout");
	for i in range(self.tiles.size()):
		var tile = self.tiles[i]
#		tile.speed = _initial_speed;
		_set_tile(tile, i - top_tiles_count);

	emit_signal("onstopped", self.index);

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

func _get_is_spinning():
	return _spinning;

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
		
