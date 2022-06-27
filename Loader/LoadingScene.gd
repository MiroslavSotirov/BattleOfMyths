extends Node

signal tiles_generated;

func _ready():
	for argument in OS.get_cmdline_args():
		if(argument == "-export_pck"): 
			return;

	yield(get_tree(), "idle_frame");
	
	Globals.singletons["Networking"].connect("fail", self, "error_received");
	
	if(JS.enabled): 
		JS.connect("init", Globals.singletons["Networking"], "init_received");
		JS.output("", "elysiumgamerequestinit");
		yield(JS, "init");
	else: 
		Globals.singletons["Networking"].request_init();
		yield(Globals.singletons["Networking"], "initreceived");

	var initdata = Globals.singletons["Networking"].initdata;
	if("language" in initdata): Globals.set_language(initdata["language"]);
	else: Globals.set_language(Globals.singletons["Networking"].default_lang);

	$LoadingSystem.required_packages.append("translation_"+Globals.current_language)
	$LoadingSystem.start();
	yield($LoadingSystem, "required_packages_loaded");
	print("Required packages Loaded.");
	print("Generating tiles...");
	generate_tile_images();
	yield(self, "tiles_generated");
	print("Tiles generated, Loading main scene...");
	var sceneloader = $LoadingSystem.load_asset("res://Main/Game.tscn");
	var prev = 0.0;
	while(sceneloader.asset == null):
		if((sceneloader.progress - prev) > 0.1):
			prev = sceneloader.progress;
			print(sceneloader.progress);
		if(JS.enabled):
			var progress = 0.5 + (sceneloader.progress * 0.3);
			JS.output(progress, "elysiumgameloadingprogress")
		yield(get_tree(), "idle_frame");
		
	get_tree().root.add_child(sceneloader.asset.instance())

	Globals.loading_done();
	print("Load successfull");
	
	#queue_free();

func generate_tile_images():
	var tilepaths = Globals.get_dir_contents("res://Main/Slot/Tiles");
	for path in tilepaths: Globals.tiles.append(load(path));
	var tile_image_generation_scene = load("res://Main/Slot/TileImageGenerator.tscn")
	var viewport = Viewport.new();
	viewport.transparent_bg = true;
	add_child(viewport);
	for tile in Globals.tiles:
		var tilescene = tile_image_generation_scene.instance();
		tilescene.set_new_state_data(tile.spine_data);
		tilescene.play_anim(tile.image_creation_animation, false);
		yield(VisualServer, "frame_pre_draw");
		viewport.size = tile.image_size;
		viewport.add_child(tilescene)
		tilescene.position = (tile.image_size/2);
		yield(get_tree(),"idle_frame");
		viewport.render_target_update_mode = Viewport.UPDATE_ONCE;
		yield(VisualServer, "frame_post_draw")
		var img = viewport.get_texture().get_data();
		img.flip_y();
		tile.static_image = ImageTexture.new();
		tile.static_image.create_from_image(img);
		viewport.remove_child(tilescene);
		
	viewport.queue_free();
	emit_signal("tiles_generated");
	
func error_received(error_id=-1):
	Globals.fsm_data["network_error"] = true;
