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

var totalTileCount : int;
var queueData = [];
var currentTiles = [];
var tiles = {};
var visible_tiles = [];

var _buffer= []; 
var _position = 0;
var _start_position = 0;
var _tiles_count = 0;

var _posible_tiles = [];
var _spinning: bool = false
var _stopping: bool = false;

var spinning : bool = false;
var stopped : bool = true;
var stopping : bool = false;

var index : int = 0;
var additional_stop_distance : int = 0;
var stop_tile_offset_top : Array;
var stop_tile_offset_bottom : Array;

var _spinPositionNormal : int = 0;
var _spinPositionTarget : float = 0;

#func initialize():
#	totalTileCount = topTileCount + visibleTileCount + bottomTileCount;
#
#	for i in range(totalTileCount):
#		_generate_tile_at(i-topTileCount);
#		currentTiles[i].setTileData(_generate_random_tiledata());
#		tiles[i-topTileCount] = currentTiles[i];
#		if(i >= topTileCount && i < topTileCount+visibleTileCount):
#			visible_tiles.append(currentTiles[i]);
#			currentTiles[i].outside_screen = false;
#		else:
#			currentTiles[i].outside_screen = true;
#		currentTiles[i].update_position();
#		slot.all_tiles.append(currentTiles[i]);
					
func get_tile_at(y):
	return currentTiles[topTileCount+y];
	
#func _process(delta):
#	pass;
#	if(spinning && spinSpeedMultiplier != 0):
#		move(spinSpeed*spinSpeedMultiplier*delta);

#func start_spin():
#	stopping = false;
#	stopped = false;
#	spinning = true;
#	$AnimationPlayer.play("ReelSpinStartAnimation");
#	emit_signal("onstartspin");
	
func set_bluramount(val):
	for tile in currentTiles: tile.blur = val * blurMultiplier;

func _start_spin_anim_end():
	pass
	
#func stop_spin(data):
#	data.invert(); ## TODO!
#	for i in range(additional_stop_distance): queueData.push_back(_generate_random_tiledata());
#	for n in stop_tile_offset_top: queueData.push_back(n);
#	for n in data: queueData.push_back(n);
#	for n in stop_tile_offset_bottom: queueData.push_back(n);
#	for i in range(stopExtraDistance + topTileCount): queueData.push_back(_generate_random_tiledata());
#
#	targetData = data;
#	#spinPosition = fmod(spinPosition, tileDistance * totalTileCount);
#	_spinPositionTarget = spinPosition - fmod(spinPosition, tileDistance) + len(queueData)*tileDistance;
#	_spinPositionTarget -= len(stop_tile_offset_top) * tileDistance;
#	#_spinPositionTarget -= len(stop_tile_offset_bottom) * tileDistance;
#
#	additional_stop_distance = 0;
#	stop_tile_offset_top.clear();
#	stop_tile_offset_bottom.clear();
#
#	stopping = true;
#	emit_signal("onstopping");
	
#func stop_spin_anim():
#	for tile in tiles.values():
#		tile.check_underneath_fat_tile();
#
#	Globals.singletons["Audio"].play(slot.reel_stop_sfx, slot.reel_stop_volume);
#	#for tile in currentTiles: tile.blur = 0.0;
#	$AnimationPlayer.play("ReelSpinStopAnimation");
#	emit_signal("onstoppinganim", self.index);
#
#func _stop_spin_anim_end():
#	spinning = false;
#	stopped = true;
#	emit_signal("onstopped", self.index);
	
#func move(amount : float):
#	if(stopping):
#		if(amount > 0): #We are moving down;
#			spinPosition = min(spinPosition + amount, _spinPositionTarget);
#		elif(amount < 0): #we are moving up
#			spinPosition = max(spinPosition + amount, _spinPositionTarget);
#		if(spinPosition == _spinPositionTarget):
#			stop_spin_anim();
#	else: 
#		spinPosition += amount;
#
#	spinPositionNormal = int(spinPosition/tileDistance);
#	if(_spinPositionNormal != spinPositionNormal):
#		var dir = sign(spinPositionNormal-_spinPositionNormal);
#		if(dir > 0):
#			for i in range(abs(spinPositionNormal-_spinPositionNormal)): 
#				shift_down_tiles();
#		elif(dir < 0):
#			for i in range(abs(spinPositionNormal-_spinPositionNormal)): 
#				shift_up_tiles();
#	_spinPositionNormal = spinPositionNormal;

#func shift_down_tiles():
#	if(len(queueData)==0): queueData.push_back(_generate_random_tiledata());
#
#	var lastTile = currentTiles[len(currentTiles)-1];
#	if(lastTile.data.feature != null && is_instance_valid(lastTile.data.feature)): 
#		lastTile.data.feature.discard(lastTile);
#
#	var order = range(1,len(currentTiles));
#	order.invert();
#	for i in order:
#		currentTiles[i].setTileData(currentTiles[i-1].data);
#
#	var firstTile = currentTiles[0];
#	firstTile.setTileData(queueData.pop_front());
#
#	for tile in tiles.values():
#		tile.check_underneath_fat_tile();
#
#	for tile in tiles.values():
#		tile.show_image();
#
#func shift_up_tiles():
#	if(len(queueData)==0): queueData.push_back(_generate_random_tiledata());
#
#	var lastTile = currentTiles[0];
#	if(lastTile.data.feature != null): lastTile.data.feature.discard(lastTile);
#
#	var order = range(len(currentTiles)-1);
#	for i in order:
#		currentTiles[i].setTileData(currentTiles[i+1].data);
#
#	var firstTile = currentTiles[len(currentTiles)-1];
#	firstTile.setTileData(queueData.pop_front());
#
#	for tile in tiles.values():
#		tile.check_underneath_fat_tile();
#
#	for tile in tiles.values():
#		tile.show_image();
		
func _generate_random_tiledata():
	return TileData.new(slot.availableTiles[randi() % len(slot.availableTiles)]);
		
#func _get_tile_pos(n):
#	return n*tileDistance;

#func _generate_tile_at(position):
#	var newTile = tileScene.instance();
#	newTile.reel = self;
#	newTile.reelPosition = _get_tile_pos(position);
#	newTile.reelIndex = index;
#	newTile.tileIndex = position;
#	currentTiles.insert(position+topTileCount, newTile);
#	newTile.init();
#	$TileContainer.add_child(newTile);

#####################################################################
func initialize(index, posibleTiles):
	_tiles_count = topTileCount + visibleTileCount + bottomTileCount;
	self.index = index;
	self._position = visibleTileCount + bottomTileCount - 1;
	self._start_position = self._position;
	self._posible_tiles = posibleTiles;
	
	if (auto_arange):
		position.x = index * tile_size.x;

#	totalTileCount = topTileCount + visibleTileCount + bottomTileCount;

	
	for i in range(_tiles_count):
		var tile = _generate_tile_at(i);
		tiles[i] = tile;
		$TileContainer.add_child(tile);
#		_generate_tile_at(i-topTileCount);
#		currentTiles[i].setTileData(_generate_random_tiledata());
#		tiles[i-topTileCount] = currentTiles[i];
#		if(i >= topTileCount && i < topTileCount+visibleTileCount):
#			visible_tiles.append(currentTiles[i]);
#			currentTiles[i].outside_screen = false;
#		else:
#			currentTiles[i].outside_screen = true;
#		currentTiles[i].update_position();
#		slot.all_tiles.append(currentTiles[i]);

func assign_tiles(serverIds):
	var ids = _reverse_data(serverIds);
	var top = _generate_random_data(topTileCount);
	var bottom = _generate_random_data(bottomTileCount);
	var data = bottom + ids + top;
	var tiles = $TileContainer.get_children();
	
	_add_to_buffer(data);
	for i in range(tiles.size()): 
		_set_tile(tiles[i], i - topTileCount);
	

#	_render()

func start_spin():
#	stopping = false;
#	stopped = false;
#	spinning = true;
	_spinning = true;
	_start_position = _position;
	
#	$AnimationPlayer.play("ReelSpinStartAnimation");

func stop_spin(serverData):
	var data = _reverse_data(serverData);
	
	_stopping = true;
	var top = _generate_random_data(topTileCount);
	_add_to_buffer(data + top);
	
	pass;
#	data.invert(); ## TODO!
#	for i in range(additional_stop_distance): queueData.push_back(_generate_random_tiledata());
#	for n in stop_tile_offset_top: queueData.push_back(n);
#	for n in data: queueData.push_back(n);
#	for n in stop_tile_offset_bottom: queueData.push_back(n);
#	for i in range(stopExtraDistance + topTileCount): queueData.push_back(_generate_random_tiledata());
#
#	targetData = data;
#	#spinPosition = fmod(spinPosition, tileDistance * totalTileCount);
#	_spinPositionTarget = spinPosition - fmod(spinPosition, tileDistance) + len(queueData)*tileDistance;
#	_spinPositionTarget -= len(stop_tile_offset_top) * tileDistance;
#	#_spinPositionTarget -= len(stop_tile_offset_bottom) * tileDistance;
#
#	additional_stop_distance = 0;
#	stop_tile_offset_top.clear();
#	stop_tile_offset_bottom.clear();
#
#	stopping = true;
#	emit_signal("onstopping");
func _set_tile(tile, index1 = 0, offest = Vector2.ZERO):
	var pos = int(_position) - index1;
#	if (self.index == 0):
#		print("pos ", pos, " - ", pos >= _buffer.size() );
	var id = 1 if pos >= _buffer.size() else _buffer[pos];

	tile.position.x = tile_size.x / 2 + offest.x;
	tile.position.y = tile_size.y / 2 + (index1) * tile_size.y + offest.y;

	tile.set_tile_data(TileData.new(id));
	tile.show_image();
	
	
func _process(delta):
	var speed = 4; # tiles per second
	var max_position = _buffer.size() - topTileCount - 1;
	var is_over = _stopping && _position >= max_position;
	if (_spinning && !is_over):
		_position = min(max_position, _position + delta * speed);
		
	if (_spinning && !_stopping && _position >= max_position):
		_add_to_buffer(_generate_random_data(int(_position + topTileCount + 1 - _buffer.size())));
		
#	if (_spinning && !isOver):
#		_position += delta * speed;
#		if (self.index == 0):
#			print(_position," | ",  _buffer.size())
	_render();
#	if (self.index == 0):
#		print(_position," | ",  _buffer.size())
#	else:
#		_render();
#	print(_position)
	
func _render():
	var reel_hight = tile_size.y * (visibleTileCount + bottomTileCount);
	var tiles = $TileContainer.get_children();
	var distance = (_position - _start_position) * tile_size.y;
	var limit = reel_hight - tile_size.y / 2;
	_start_position = _position; # TODO rename to last_position
	
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
