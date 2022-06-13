extends Node

var singletons = {};
var spindata = {};
var fsm_data := {};

signal allready;
signal resolutionchanged(landscape, portrait, ratio, zoom);
signal configure_bets(bets, defaultbet);
signal update_balance(new, currency);
signal update_view(view);
signal apply_language();
signal skip;

var round_closed : bool = false;
var all_ready : bool = false;

var currentBet : float;

var screenratio : float;
var landscape : bool = false;
var portrait : bool = false;

var resolution : Vector2;
var zoom_resolution_from : float = 2048+1024;
var zoom_resolution_to : float = 1024;
var landscaperatio : float = 16.0/9.0;
var portraitratio : float = 9.0/20.0;

var visibleReelsCount : int = 0;
var visibleTilesCount : int = 0;
var canSpin : bool setget ,check_can_spin;

var current_language = "NONE";
var currency_symbol = "$";
var currency_code = "USD";
var currency_position = true;

var tiles : Array = [];

func _ready():
	JS.connect("focused", self, "on_focused");
	JS.connect("unfocused", self, "on_unfocused");

func on_focused(data):
	print("Resuming")
	get_tree().paused = false;
	
func on_unfocused(data):
	print("Pausing")
	get_tree().paused = true;
	
func loading_done():
	print("loading done");
	yield(get_tree(),"idle_frame")
	emit_signal("allready");
	all_ready = true;
	yield(get_tree(),"idle_frame")
	singletons["Networking"].apply_init();
	emit_signal("apply_language");
	yield(get_tree(),"idle_frame")
	_resolution_changed(resolution);
	JS.output("", "elysiumgameloadingcomplete");
	
func register_singleton(name, obj):
	singletons[name] = obj;

func get_fsm_data(key):
	return fsm_data.get(key, false);
	
func create_coroutine_timer(time):
	yield(get_tree().create_timer(time), "timeout");
	return time;

func _process(delta):
	var res = Vector2(OS.window_size.x, OS.window_size.y); #get_viewport().get_visible_rect().size;
	if(resolution != res):
		_resolution_changed(res);
		
func _resolution_changed(newres : Vector2):
	#newres *= 2
	yield(VisualServer, "frame_post_draw");
	screenratio = clamp(inverse_lerp(landscaperatio, portraitratio, newres.x/newres.y), 0, 1);
	landscape = screenratio > 0.5;
	portrait = screenratio <= 0.5;
	var zoom : float = min(newres.x, newres.y);
	zoom = inverse_lerp(zoom_resolution_from, zoom_resolution_to, zoom);
	resolution = newres;
	emit_signal("resolutionchanged", landscape, portrait, screenratio, zoom);
	prints("New screen ratio ", newres, landscape, portrait, screenratio, zoom)

func check_can_spin():
	return all_ready && !singletons["Fader"].visible && !singletons["Slot"].spinning;

func format_money(v):
	v = float(v);
	if(currency_position):
		return currency_symbol+("%.2f" % v);
	else:
		return ("%.2f" % v)+currency_symbol;

func safe_set_parent(obj, newparent):	
	yield(VisualServer, "frame_post_draw");
	if(obj == null || !is_instance_valid(obj)): return;
	var transform = obj.get_global_transform();
	if(obj.get_parent() != null):
		obj.get_parent().remove_child(obj);
	newparent.add_child(obj);
	obj.set_global_transform(transform);
	update_all(obj);		
	obj.update();

func update_all(obj):
	for child in obj.get_children():
		if("update" in child): child.update();
		if("_draw" in child): child._draw();
		update_all(child);
		
func set_jurisdiction(jrd):
	pass;
	
func set_debug(dbg):
	pass;
	
func set_currency(currency):
	singletons["Networking"].set_currency(currency);
	
func set_stake(data):
	#currentBet = float(stake);
	Globals.singletons["Stateful"].switch_to_state(data.stake);
	update_win_configs(data.stake);
	
func set_language(lang : String):
	lang = lang.to_upper();
	prints("LANGUAGE SET TO ",lang);
	current_language = lang;
#	singletons["AssetLoader"].download_language(lang);
	
func configure_bets(bets, defaultbet):
	currentBet = float(defaultbet);
	var biggestbet = float(bets[-1]);
	update_win_configs(biggestbet);

func update_win_configs(stake):
	print("update_win_configs")
	stake = float(stake);
	singletons["WinBar"].bangup_factor = stake * 3;
	
	singletons["BigWin"].bangup_factor = stake * 2;
	singletons["BigWin"].big_win_limit = stake * 10.0;
	singletons["BigWin"].super_win_limit = stake * 25.0;
	singletons["BigWin"].mega_win_limit = stake * 50.0;

func get_dir_contents(rootPath: String) -> Array:
	var files = []
	var dir = Directory.new()
	
	var open = dir.open(rootPath);
	if open == OK:
		dir.list_dir_begin(true, false)
		_add_dir_contents(dir, files)
	else:
		push_error("An error occurred when trying to access the path "+rootPath)

	return files

func _add_dir_contents(dir: Directory, files : Array):
	var file_name = dir.get_next()
		
	while (file_name != ""):
		var path = dir.get_current_dir() + "/" + file_name

		if dir.current_is_dir():
			#print("Found directory: %s" % path)
			var subDir = Directory.new()
			subDir.open(path)
			subDir.list_dir_begin(true, false)
			_add_dir_contents(subDir, files)
		else:
			#print("Found file: %s" % path)
			files.append(path)

		file_name = dir.get_next()
		while(file_name.begins_with(".")): 
			file_name = dir.get_next()

	dir.list_dir_end()
