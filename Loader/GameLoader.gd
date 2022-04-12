extends Node

var loader;
var wait_frames
var time_max = 100 # msec

func _ready():
	loader = ResourceLoader.load_interactive("res://Game.tscn")
	
func _process(time):
	var t = OS.get_ticks_msec()
	# Use "time_max" to control for how long we block this thread.
	while OS.get_ticks_msec() < t + time_max:
		var err = loader.poll()

		if err == ERR_FILE_EOF: # Finished loading.
			var resource = loader.get_resource()
			loader = null
			set_new_scene(resource)
			break
		elif err == OK:
			update_progress()
		else: # Error during loading.
			prints("ERROR", err);
			
func update_progress():
	var progress = lerp(0.0,0.9,float(loader.get_stage()) / loader.get_stage_count());
	if(JS.enabled):
		JS.output(progress, "elysiumgameloadingprogress")

func set_new_scene(scene_resource):
	get_node("/root").add_child(scene_resource.instance())
	Globals.loading_done();
	queue_free();
