extends Node
export(Array) var tiles;
export(PackedScene) var tile_image_generation_scene;
var language_loaded : bool = false;
var tiles_generated : bool = false;
var current_language : String = "";

signal lang_downloaded (lang);
signal tiles_generated;

func _ready():
	Globals.register_singleton("AssetLoader", self);
	
func generate_tile_images():
	for tile in tiles:
		var tilescene = tile_image_generation_scene.instance();
		tilescene.set_new_state_data(tile.spine_data);
		tilescene.play_anim(tile.image_creation_animation, false);
		yield(VisualServer, "frame_pre_draw");
		$Viewport.size = tile.image_size;
		$Viewport.add_child(tilescene)
		tilescene.position = (tile.image_size/2);
		yield(get_tree(),"idle_frame");
		$Viewport.render_target_update_mode = Viewport.UPDATE_ONCE;
		yield(VisualServer, "frame_post_draw")
		var img = $Viewport.get_texture().get_data();
		img.flip_y();
		tile.static_image = ImageTexture.new();
		tile.static_image.create_from_image(img);
		$Viewport.remove_child(tilescene);
	$Viewport.queue_free();
	
	emit_signal("tiles_generated");
	
func download_language(lang):
	if(JS.enabled):
		lang = lang.to_upper();

		var path = JS.get_path()+"translations/"+lang+".pck";
		prints(path);
		$HTTPRequest.download_file = "res://"+lang+".pck";
		$HTTPRequest.request(path);
		var res = yield($HTTPRequest, "request_completed");
		#result, response_code, headers, body
		if(res[0] != 0):
			prints("Error downloading language ", res[0], lang, "falling back to EN");
			download_language("EN");
			return;
			
		ProjectSettings.load_resource_pack("res://"+lang+".pck")
		language_loaded = true;
		emit_signal("lang_downloaded", lang);
		prints("LOADED NEW LANGUAGE ", lang);
	else:
		ProjectSettings.load_resource_pack("res://Translations/export/"+lang+".pck")
		language_loaded = true;
		yield(get_tree(), "idle_frame");
		emit_signal("lang_downloaded", lang);
		prints("LOADED NEW LANGUAGE ", lang);
