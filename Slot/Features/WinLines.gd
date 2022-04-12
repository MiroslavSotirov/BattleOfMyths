tool
extends Control

export (Array) var lines;
export (int) var lines_count setget set_lines_count;
export (int) var reel_count = 5;
export (PackedScene) var tile_scene; 
export (PackedScene) var line_scene; 
export (Color) var darken_color;

var shown = false;
var shown_tiles : Array; 
var tiles_to_hide : Array;

signal ShowEnd;

func _ready():
	if(!Engine.editor_hint):
		Globals.register_singleton("WinLines", self);
		yield(Globals, "allready")
		rect_position = Globals.singletons["Slot"].get_node("ReelContainer").rect_position;
		rect_size = Globals.singletons["Slot"].get_node("ReelContainer").rect_size;

func set_lines_count(n):
	lines_count = n;
	var diff = len(lines) - n;
	if(diff < 0):
		for i in range(abs(diff)):
			var a = [];
			for b in range(reel_count): a.append(0);
			lines.append(a);
	elif(diff > 0):
		for i in range(diff): lines.pop_back();

func show_lines(windata):
	yield(get_tree(), "idle_frame");
	shown = true;
	visible = true;
	Globals.singletons["WinlinesFadeAnimationPlayer"].play("To_Winline")
	tiles_to_hide = Globals.singletons["Slot"].all_tiles.duplicate();
	for win in windata:
		if(win.has("winline")):
			if(win["winline"] < 0): continue;
		else:
			win["winline"] = 0;
		show_line(win["symbol_positions"], int(win["winline"]));
		yield(get_tree().create_timer(0.1), "timeout")
	
	hide_nonline_tiles();
		
	emit_signal("ShowEnd");
		
func show_line(positions, lineid):
	var line_positions = [];
	
	var linex = 0
	for pos in lines[lineid]:
		var tile = Globals.singletons["Slot"].get_tile_at(linex,pos);
		line_positions.append(tile);
		linex += 1;
	
	for pos in positions:
		#TODO: dynamic
		var y = int(pos)%Globals.visible_tiles_count;
		var x = floor(pos/Globals.visible_tiles_count);		
		var tile = Globals.singletons["Slot"].get_tile_at(x,y);
		if(tile.fat_tile): 
			tile = tile.fat_tile;
			pos = (tile.reelIndex * Globals.visible_tiles_count) + tile.tileIndex;
		tiles_to_hide.erase(tile);
		if(!shown_tiles.has(pos)): 
			shown_tiles.append(pos);
			var wintile = tile_scene.instance();		
			$TilesContainer.add_child(wintile);
			wintile.tile = tile;
			#wintile.position = tile.position;
			wintile.init();
	
	var winline = line_scene.instance();
	$LinesContainer.add_child(winline);
	winline.global_position = line_positions[0].global_position;
	winline.positions = line_positions;
	winline.init();
	
func hide_nonline_tiles():
	var temp : Tween = Tween.new();
	add_child(temp);
	temp.connect("tween_all_completed", temp, "queue_free");
	for tile in tiles_to_hide:
		temp.interpolate_property(tile, "modulate",
				Color.white, darken_color, 0.5,
				Tween.TRANS_LINEAR, Tween.EASE_IN_OUT);
	temp.start();
	yield(temp, "tween_all_completed");
	temp.queue_free();
	
func show_nonline_tiles():
	var temp : Tween = Tween.new();
	add_child(temp);
	temp.connect("tween_all_completed", temp, "queue_free");
	for tile in tiles_to_hide:
		temp.interpolate_property(tile, "modulate",
				darken_color, Color.white, 0.25,
				Tween.TRANS_LINEAR, Tween.EASE_IN_OUT);
	temp.start();
	yield(temp, "tween_all_completed");
	temp.queue_free();
	
func hide_lines():
	shown = false;
	visible = false;
	
	for c in $LinesContainer.get_children():
		$LinesContainer.remove_child(c)
		c.queue_free();

	for c in $TilesContainer.get_children():
		c.reset();
		$TilesContainer.remove_child(c)
		c.queue_free();
	
	shown_tiles.clear();
	
	show_nonline_tiles();		
	Globals.singletons["WinlinesFadeAnimationPlayer"].play("To_Normal")
