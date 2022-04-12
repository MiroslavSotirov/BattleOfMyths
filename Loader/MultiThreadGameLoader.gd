extends Node

var queue;
var start_time;
var end_time;
var directory;

func _ready():
	print("Loading Scene Initialized");
	queue = preload("res://Loader/resource_queue.gd").new()
	queue.start();
	start_time = OS.get_ticks_msec();
	queue.queue_resource("res://Game.tscn", true)

func _process(_delta):
	if queue.is_ready("res://Game.tscn"):
		set_process(false)
		set_new_scene(queue.get_resource("res://Game.tscn"));
	else:
		update_progress();
			
func update_progress():
	var progress = float(queue.get_progress("res://Game.tscn") * 100) - 0.1
	if(JS.enabled):
		JS.output(progress, "elysiumgameloadingprogress")

func set_new_scene(scene_resource):
	end_time = OS.get_ticks_msec();
	prints("Loading times:", start_time, end_time, end_time-start_time);
	get_node("/root").add_child(scene_resource.instance())
	Globals.loading_done();
	queue_free();
	
func dir_contents(path, files = null):
	var dir = Directory.new()
	if(files == null): files = [];
	if dir.open(path) == OK:
		dir.list_dir_begin(true, true)
		var file_name = dir.get_next()
		while file_name != "":
			var newpath = dir.get_current_dir()+"/"+file_name;
			if dir.current_is_dir():
				dir_contents(newpath, files);
			else:
				files.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end();
		return files
	else:
		prints("An error occurred when trying to access the path.",path)
		return null
