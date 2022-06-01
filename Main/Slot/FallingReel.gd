extends Reel
class_name FallingReel

export (float) var blurMultiplier : float;
export (float) var bluramount : float setget set_bluramount;

export (int) var topTileCount : int = 0;
export (int) var visibleTilesCount : int = 4;
export (int) var bottomTileCount : int = 0;
export (Dictionary) var animations = {
	popup = { name = "popup", loop = false, type = Tile.AnimationType.SPINE },
	hide = { name = "hide", type = Tile.AnimationType.SPINE },
	drop = { name = "drop", type = Tile.AnimationType.TIMELINE }
};

export (float) var delayPerTile = 0.05;
export (int) var acceleration = 380;
export (int) var maxSpeed = 200;
export (int) var initialSpeed = 0;

export (Array) var targetData : Array;
export (PackedScene) var tileScene;

export (bool) var auto_arrange = true;
export (Vector2) var tile_size = Vector2.ZERO;

signal onstartspin;
signal onstopping;
signal onstoppinganim;
signal onstopped;
signal oncleared;

var tiles : Array setget , _get_tiles;
var index : int = 0;
var is_spinning: bool setget , _get_is_spinning;

var _buffer = []; 
var _position = 0;
var _visible_tiles: Array setget , _get_visible_tiles;
var _removed_tiles = [];

var _posible_tiles = [];
var _spinning: bool = false
var _stopping: bool = false;
var _tiles_natural_positions = [];
var _speed = initialSpeed;
var _time = 0;
var _edges = { tiles = [], slot = 0 }; # the farthest a tile can fall
var _filling: bool = false; # true when the screen is being filled with the new tiles /the spin result/

#var spinning : bool = false;
#var stopped : bool = true;
#var stopping : bool = false;

func get_tile_at(index):
	return self.tiles[topTileCount + index];

# returns the tile position relative to the slot
func get_tile_position(index):
	var tile = get_tile_at(index);
	return tile.global_position;
	#return Vector2(tile.position.x + position.x, tile.position.y);

func set_bluramount(val):
#	for tile in currentTiles: tile.blur = val * blurMultiplier;
	pass

func _start_spin_anim_end():
	pass

func initialize(index, posibleTiles):
	var tiles_count = topTileCount + visibleTilesCount + bottomTileCount;
	self.index = index;
	self._position = visibleTilesCount + bottomTileCount - 1;
	self._posible_tiles = posibleTiles;
	
	if (auto_arrange):
		position.x = index * tile_size.x;
	
	for i in range(tiles_count):
		var tile = tileScene.instance();
		$TileContainer.add_child(tile);
	
	_edges.slot = tile_size.y * (visibleTilesCount) + tile_size.y / 2;
	for i in range(visibleTilesCount):
		_edges.tiles.append(i * tile_size.y + tile_size.y / 2);

func set_initial_screen(server_data):
	var ids = _reverse_data(server_data);
	var top = _generate_random_data(topTileCount);
	var bottom = _generate_random_data(bottomTileCount);
	var data = bottom + ids + top;
	
	_add_to_buffer(data);

	for i in range(self.tiles.size()):
		_set_tile(self.tiles[i], i - topTileCount);

func shift():
	_spinning = true;
	_filling = true;
	_stopping = true;
	
func start_spin():
	for i in range(self.tiles.size()):
		self.tiles[i].speed = initialSpeed;
		_set_tile(self.tiles[i], i - topTileCount);

	_spinning = true;
	_removed_tiles = [];

func stop_spin(server_data):
	var data = _reverse_data(server_data);
	var top = _generate_random_data(topTileCount);
	
	_add_to_buffer(data + top);

	if (!_filling): yield(self, "oncleared");

	_stopping = true;
	_position = _buffer.size() - topTileCount - 1;

	for i in range(self._visible_tiles.size()): 
		_set_tile(self._visible_tiles[i], i, Vector2(0, (-visibleTilesCount - 2) * tile_size.y));
	
	call_deferred("_fill");
	yield(self, "onstopped");

func replace_all_tiles(ids):
	if (ids.size() != visibleTilesCount):
		var err = "expected %s of new tile ids, got %s";
		push_error(err % [visibleTilesCount, ids.size()]);
		return;
		
	for i in range(ids.size()):
		print("i ", i,  "id ", ids[i])
		replace_tile(i, ids[i]);

func replace_tile(index, newId):
	if (_spinning):
		push_error("Tiles can be replaced only on a stopped reel");
		return;
		
	var i = int(_position) - index;
	_buffer[i] = newId;
	_set_tile(self._visible_tiles[index], index);
	
func add_tiles(data):
	if (_removed_tiles.size() == 0): return Promise.resolve();
	var new_tiles = _reverse_data(data.slice(0, _removed_tiles.size() - 1));

	_buffer = _buffer.slice(0, int(_position)) + _reverse_data(data.slice(0, _removed_tiles.size() - 1));
	var offsets = _get_tiles_offset(_reverse_data(_removed_tiles));
	for i in range(self._visible_tiles .size()):
		_set_tile(self._visible_tiles[i], i, offsets[i]);

	_removed_tiles = [];
	shift();
	return yield(self, "onstopped");
	
func remove_tiles(indexes):
	indexes.sort();
	_removed_tiles = indexes;
	_buffer =  _remove_from_buffer(indexes);
	
	var promises = [];
	for index in indexes:
		var tile = self._visible_tiles[index];
		promises.push_back(tile.hide(animations.hide.type, animations.hide.name));

	yield(Promise.all(promises), "completed");

func popup_tiles(indexes):
	var promises = [];
	for index in indexes:
		var tile = self._visible_tiles[index];
		var animation = animations.popup;
		promises.push_back(tile.popup(animation.type, animation.name, animation.loop));

	yield(Promise.all(promises), "completed");
	
func get_tiles_with_id(id):
	var tiles = [];
	for tile in self.tiles:
		if(tile.id == id): tiles.append(tile);
	return tiles;
	
func _get_tiles_offset(removed_tiles):
	var offsets = [];
	for i in range(visibleTilesCount):
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
	
	var fallen_tiles = 0;
	_time = _time + delta;

	for i in range(visibleTilesCount):
		if ((visibleTilesCount - i) * delayPerTile > _time): continue;
		var tile = self.tiles[i + topTileCount];
		var limit = _edges.tiles[i] if _filling else _edges.slot;

		if (tile.position.y >= limit):
			_on_drop(tile, i);
			fallen_tiles += 1;
		else:
			tile.speed = min(maxSpeed, tile.speed + delta * acceleration);
			tile.update_position(Vector2(0, min(limit - tile.position.y, tile.speed)));

	if (fallen_tiles == visibleTilesCount):
		_on_clear();

func _on_drop(tile, i):
	if (_filling && tile.speed > initialSpeed): 
		tile.play_animation(animations.drop.type, animations.drop.name);

	tile.speed = initialSpeed;
	
func _on_stoppped():
	_spinning = false;
	_stopping = false;
	_time = 0;

#	TODO 0.5 is the duration of the drop animation
	yield(get_tree().create_timer(0.5), "timeout");
	for i in range(self.tiles.size()):
		var tile = self.tiles[i]
		_set_tile(tile, i - topTileCount);

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
	return self.tiles.slice(topTileCount, visibleTilesCount + topTileCount - 1);

func _get_is_spinning():
	return _spinning;

func _fill():
	_filling = true;
	
func _on_clear():
	if (!_filling):
		_time = 0;
		emit_signal("oncleared", self.index);
	else:
		_filling = false;
		_on_stoppped();
