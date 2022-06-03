GDPC                                                                                  res://Loader/PackageExporter.gd      	                         res://Loader/Mapper.gd#      W                         res://Loader/default_env.tresz      �                          res://Loader/Globals.gd      �                         res://Loader/LoadingScene.tscn�$      v                         res://Loader/AssetLoader.gdb(      X                         res://Loader/LoadingSystem.gd�+      �                         res://Loader/LoadingScene.gd;4                               res://Loader/PackageLoader.gdU<      �                          res://Loader/HeadlessExporter.gd�A                            !   res://Loader/UI/OpenSans-Bold.ttf�C      ��                     $   res://Loader/UI/default_dynfont.tres��     �                          res://Loader/JSComms/JS.gdc�     �                         res://Loader/Promise.gd`�     �                         res://project.binaryI�     1,                      tool
extends Node
class_name PackageExporter

export(Array,String,DIR) var targetpaths : Array;
export(Array,String,DIR) var ignorepaths : Array;
export(bool) var is_loader : bool = false;

signal export_completed;

func _get_tool_buttons(): return ["export_pck"]

func export_pck():
	prints("Exporting", name);
	
	var valid_extensions = ["png", "jpg", "webp", "tscn", "tres", "gd", "ttf", "json", "atlas", "txt"];
	var paths = {};
	
	for folder in targetpaths:
		var files = get_dir_contents(folder);
		for path in files:	
			if(!valid_extensions.has(path.get_extension())): continue;
			var import = path+".import";
			
			if(files.has(import)):
				paths[import] = import;
				var file = File.new()
				file.open(import, File.READ)
				var content = file.get_as_text()
				file.close()
				var l = content.find('dest_files=[ "')
				var r = content.find('" ]', l)
				var importpath = content.substr(l, r-l).lstrip('dest_files=[ "');
				paths[importpath] = importpath
			else:
				paths[path] = path;

	var packer = PCKPacker.new()
	var pckname = "res://packages/"+name+".pck";
	packer.pck_start(pckname);
			
	for path in paths.keys(): 
		#print(path, " -> ", paths[path])
		packer.add_file(paths[path], path)
		
	if(is_loader):
		ProjectSettings.save_custom("res://project.binary")
		#packer.add_file("res://project.godot", "res://project.godot")
		packer.add_file("res://project.binary", "res://project.binary")

		
	packer.flush()
	print("done")
	emit_signal("export_completed");

func get_dir_contents(rootPath: String) -> Array:
	var files = []
	var dir = Directory.new()

	if dir.open(rootPath) == OK:
		dir.list_dir_begin(true, false)
		_add_dir_contents(dir, files)
	else:
		push_error("An error occurred when trying to access the path.")

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

extends Node

static func _callOn(object, method: String, paramether, i, use_index = false):
		if (paramether && use_index):
			return object.call(method, paramether, i);
		elif (paramether && !use_index):
			return object.call(method, paramether);
		elif (!paramether && use_index):
			return object.call(method, i);
		else:
			return object.call(method);
	
static func map(elements: Array, object: Object, method: String, use_index = false):
	var result = [];

	for i in range(elements.size()):
		var element = elements[i];
		result.push_back(_callOn(object, method, null, i, use_index));
#		result.push_back(object.call(method, element, i));

	return result;
	
static func callOnElements(elements: Array, method: String, paramethers = null, use_index = false):
	var result = [];
	for i in range(elements.size()):
		var p = paramethers[i] if paramethers && paramethers[i] else null;
#		elements[i].call(method, p)
#		result.push_back(elements[i].call(method, p))
		result.push_back(_callOn(elements[i], method, p, i, use_index))
#		result.push(_callOn(elements[i], method, p, i, use_index));

	return result;
[gd_resource type="Environment" load_steps=2 format=2]

[sub_resource type="ProceduralSky" id=1]

[resource]
background_mode = 1
background_sky = SubResource( 1 )
extends Node

var singletons = {};
var spindata = {};
var fsm_data := {};

signal allready;
signal resolutionchanged(landscape, portrait, ratio, zoom);
signal configure_bets(bets, defaultbet);
signal update_balance(new, currency);
signal update_view(view);
signal skip;

var round_closed : bool = false;

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
	yield(get_tree(),"idle_frame")
	yield(get_tree(),"idle_frame")
	_resolution_changed(resolution);
	
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
	return !singletons["Fader"].visible && !singletons["Slot"].spinning && singletons["Game"].round_ended;

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
[gd_scene load_steps=5 format=2]

[ext_resource path="res://Loader/LoadingSystem.gd" type="Script" id=1]
[ext_resource path="res://Loader/LoadingScene.gd" type="Script" id=2]
[ext_resource path="res://Loader/PackageExporter.gd" type="Script" id=3]
[ext_resource path="res://Loader/HeadlessExporter.gd" type="Script" id=4]

[node name="LoadingScene" type="Node"]
script = ExtResource( 2 )

[node name="LoadingSystem" type="Node" parent="."]
script = ExtResource( 1 )
required_packages = [ "main" ]

[node name="PackageExporters" type="Node" parent="."]
script = ExtResource( 4 )

[node name="index" type="Node" parent="PackageExporters"]
script = ExtResource( 3 )
targetpaths = [ "res://Loader" ]
is_loader = true

[node name="main" type="Node" parent="PackageExporters"]
script = ExtResource( 3 )
targetpaths = [ "res://Main", "res://addons/visual_fsm", "res://addons/BitmapFontEasy" ]
extends Node
class_name AssetLoader

var asset_name : String;
var progress : float = 0.0;
var time_max : int = 10; # msec
var loader;
var asset;
signal loaded(resource);

func _init(asset_name):
	self.asset_name = asset_name;

func _ready():
	loader = ResourceLoader.load_interactive(asset_name)
	
func _process(time):
	var t = OS.get_ticks_msec()
	# Use "time_max" to control for how long we block this thread.
	while progress < 1.0:
		var err = loader.poll()

		if err == ERR_FILE_EOF: # Finished loading.
			load_complete(loader.get_resource());
			break
		elif err == OK:
			progress = float(loader.get_stage()) / float(loader.get_stage_count());
		else: # Error during loading.
			prints("ERROR LOADING ASSET", asset_name, err);
			
		yield(get_tree(), "idle_frame");

func load_complete(resource):
	asset = resource;
	emit_signal("loaded", resource)
extends Node
class_name LoadingSystem

export (Array, String) var required_packages : Array = [];
export (Array, String) var optional_packages : Array = [];

var loaded_packages : Array = [];

var loaders = [];
var progress : float = 0.0;

signal asset_loaded(name, asset);
signal package_loaded(name);
signal required_packages_loaded;
signal optional_packages_loaded;

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS;
	
func start():
	load_required_packages();
	yield(self, "required_packages_loaded");
	load_optional_packages();

func load_required_packages():
	for pck_name in required_packages:		
		load_package(pck_name);
	
	var n = 1.0/len(required_packages);
	while(progress < 1.0):
		progress = 0.0;
		for loader in loaders: progress += loader.progress * n;
		if(JS.enabled):
			JS.output(progress * 0.5, "elysiumgameloadingprogress")
		yield(get_tree(), "idle_frame");
		
	emit_signal("required_packages_loaded");
	
func load_optional_packages():
	for pck_name in optional_packages:
		load_package(pck_name);
		yield(self, "package_loaded");
		
	emit_signal("optional_packages_loaded");

func load_package(pck_name):
	var loader = PackageLoader.new(pck_name);
	add_child(loader);
	loaders.append(loader);
	loader.connect("loaded", self, "load_package_completed", [pck_name]);
	return loader;
	
func load_package_completed(pck_name):
	loaded_packages.append(pck_name)
	emit_signal("package_loaded", pck_name);
	
func load_asset(assetname):
	var loader = AssetLoader.new(assetname);
	add_child(loader);
	loaders.append(loader);
	loader.connect("loaded", self, "load_asset_completed", [assetname]);
	return loader;

func load_asset_completed(assetname, asset):
	emit_signal("asset_loaded", assetname, asset);
	
func is_pck_loaded(name):
	if(loaded_packages.has(name)):
		call_deferred("emit_signal", name);
	else:
		show_loading_screen(name);
	return self;

func show_loading_screen(name):
	get_tree().paused = true;
	print("WAITING...");
	while yield(self.is_pck_loaded(name), "package_loaded") != name: pass
	get_tree().paused = false;
	print("DONE!");

#while yield(PackageLoader.is_pck_loaded(name), "package_loaded") != name: pass
#var bonus = load(bonuspath);
extends Node

signal tiles_generated;

func _ready():
	for argument in OS.get_cmdline_args():
		if(argument == "-export_pck"): 
			return;
			
	#var lang = "translations_EN.pck";
	#$LoadingSystem.required_packages.append(lang);
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
		print(tile.id)
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
extends Node
class_name PackageLoader

var package_name : String;
var progress : float = 0.0;
var time_max : int = 100; # msec
var completed : bool = false;
var loader = null;

signal loaded;

func _init(package_name):
	self.package_name = package_name;

func _ready():
	#loader = ResourceLoader.load_interactive("res://Game.tscn")
	prints("LOADING PACKAGE", package_name);
	if(JS.enabled):
		var path = JS.get_path()+"packages/"+package_name+".pck";
		loader = HTTPRequest.new();
		add_child(loader);
		loader.download_file = "res://"+package_name+".pck";
		loader.request(path);
		var res = yield(loader, "request_completed");
		#result, response_code, headers, body
		if(res[0] != 0):
			prints("Error downloading package ", package_name, res[0], package_name);
			progress = 1.0;
			return;
		ProjectSettings.load_resource_pack("res://"+package_name+".pck", true)
		progress = 1.0;
		emit_signal("loaded");
	else:
		ProjectSettings.load_resource_pack("res://Packages/"+package_name+".pck", true)
		yield(get_tree(), "idle_frame");
		progress = 1.0;
		emit_signal("loaded");
		
	prints("LOADED PACKAGE", package_name);
	
func _process(time):
	if(loader != null):
		var maxsize : float = float(loader.get_body_size());
		if(maxsize < 0): maxsize = float(1024*1024*64);
		if(progress < 1.0):
			progress = float(loader.get_downloaded_bytes()) / maxsize;

func load_complete(resource):
	emit_signal("loaded", resource)
tool
extends Node
func _get_tool_buttons(): return ["export_all_pck"]

func _ready():
	var do_export = false;
	for argument in OS.get_cmdline_args():
		if(argument == "-export_pck"): 
			do_export = true;
			break;
			
	if(do_export): export_all_pck(true);

func export_all_pck(quit=false):
	print("EXPORTING PCK...")
	var children = get_children();
	for child in children:
		child.export_pck();
		#yield(child, "export_completed")
	
	print("COMPLETED")
	if(quit):
		OS.execute("kill", ["-3", String(OS.get_process_id())]);
       GDEF|� ��   .GPOS   ��   GSUB�)� ��  �OS/2�m� cP   `cmap���� c�  �cvt -� p   �fpgm�s�u g8  �gasp   �|   glyf��   K�head%I� TX   6hhea)
R c,   $hmtx$�  T�  �loca��`+ M   Vmaxp5 L�    nameXb}- p�  �post�	o tx  prep�	�k o   �  �  
�   @	  /2/3993310!!7!!�I��hy����Jh�   u����   &@

TY ??+ 3933310#!4632#"&��3Z��ZVS[\RT\����TVXRO[Y   ��B�   @  ?3�233�210#!#�)�)�)�)�����   -  ��   }@D		
 

 ! 

 ?3?399//333333333393939393910!!####5!7#5!333337#�/��M�N�L�J�/�!M�M�N�N���/�L���j��j������i��i���   X��D   & , �@E$**!)' '#!!  -.*'  $!'+'!	%OYPY-  ?99//3�+ 3+ 939939999339922999333333310#5&''&&546753&'4&'65D�ω��W�`Cƥ�ˉ�^��åM��DD��n=D�ɟ���Q+B6N������
R�@��Kn�g*:��,9�  ?���� 	   " - J@$
 )###./ +& ?3�2???3�2993�2933�293103254#"#"&5!2%#3254#"#"&5!2;-2``2-�����Y������+�-2``2-�����Y�� }��{}��������J��}��{}������   R�� �  & 1 q@9-#
 
''  32!
$$//*MY!LY ??+ ?+ 9/9399933339339999310!!'#"$5467&&5463267!%3274&#"66 ��s�����y�KD�úߊ�G4>$~P���e~e��:CgH9CM_V\q�࿉�TV�]����w�Y��u����c�Vf=J,`�5=@;Xj0]  ����  �  ?�3310#�)�)���   R��y�   @

 $ ??3333331073#&R����������1	ή��2���7���   =��d�   @

 
$ ??33333310#654'3d����������1���:���������1  ?V  5@	

  ?�293393933393910%'%7�)u!���㜉����'m)��h���y9��w)�hp  X �9�  &@		  	  /3332293333310!5!3!!#��}����}�d���z��  ?��� �  �  /�33�210%#7!�4|�A$����
�  =�V�  �   /333105!=���  u���9  @
  	TY	 ?+331074632#"&uZVS[\RT\�TVXRO[Y     D�  @   ??993310!D����!��J�  J��H�   (@  	OY	OY ?+ ?+993310!" !2 326&#"H���������5]nl`akm^�����|s�o��������
��  y  N� 
 *@	  	 ??3939339910!!77'3N��M����N��M��w  N  P�  =@ 

NYNY ?+ 9?+ 9399333310!!5>54&#"'>32!P�o�d,aQU�W�l��h��tG���}�s��n;XVNH�\L)d�te����   N��B� & [@/"  '(!$OYPY
$
OY
 ?+ 3?9/_^]+ 9+ 39933339910!"'32654&##532654#"'6!2���������U�d����oq���H�[���o��$����O+6hsgV�Yl�0;Ր�   #  q� 
  F@"	  PY	 ??39/3+ 3933393339910#!!5!3!5467#q��������"
%4��/��/���i�>�RN�k  d��5�  V@+	 OY  NYOY ?+ ?+ 9/3+ 99399393993102 !"'3 54!"'!!76f��������O�^��5�({7��#=������O*5��B�����  H��P�  $ A@!""  %&PYOYOY ?+ ?+ 9/+99339910 !2&#"3632 #"&2654&#"Hon}GYW��d	c�������cjcd^�}m���`�������� ��{k{zQw�   7  P�  .@  NY  ??+ 999393103!!�%�/�����   H��J�  " . S@),	&		/0!!)) QY #QY  ?+ ?+ 93939939329399102#"$5467&&54$32654&'"6654&J�|��������}nxhsrq��OaMebNdɿ�p�EX�r��̻}�JO�k����V`cQCuBb�QD<_2.`?EP   B��J�  % ?@ ##  &' PYOYPY ?+ ?+ 9/+99399210 !"'532667##"&54 32%"32654&J�����CT\��j:�r������`lbd^�}F�P�V�[ë^L��������|j|{Pw�   u���s   &@  TY	TY	 ?+ ?+33331074632#"&4632#"&uZVS[\RT\ZVS[]QT\�TVXRO[Y�TVXRQYX  ?���s   (@
TY
 /�?+33�23310%#74632#"&�4|�A$/ZVS[]QT\����
��TVXRQYX   X �9   '@    =/333233993310%59���T����������   X�9    $@	 P`  /33/]33233105!5!X���%���}��   X �9   +@    =/3333339933105X��T���=����J   ����  % D@"   &' 	  ##TY#
OY ?+ ?+ 3/_^]99393331054676654&#"'6324632#"&RmiC`V��m����d�`3��ZVS[\RT\�J`�PK^:ADb�}ƥn�dGJ<<��TVXRO[Y   f�f�� 4 ? Y@+9955;(!!- - @A77
=

*1$* /3?399//33333993393393910#"&'##"&54 3232654&&#" !267!  4$!232677&#"�\�oJrl����V�CL@L����֟'j�{������W���Z�� �Z^
3@}���G:�չ�!���������������/-�[�d�����������      ��   C@!   LY  ?3?39/+3333933999910!!!!&'7j��j��{���%!�\����D`�|$��   �  ��     V@,"!MY LY LY  ?+ ?+ 9/_^]+ 93333393910! #!32654&##32654!��7{f�{�����6�~q{��ʀz�������
����sNZTI����be�  w����  1@  LY
LY
 ?+ 3?+ 3333310"!27#  4$32&&%��o�۴������7���dR������M��K�j�W�g�':  �  u�   (@	  LYLY ?+ ?+333310 !!!  !#3 u�e�|�b�f����`���������������H  �  �  E@$  

	LYLY
LY ?+ ?+ 9/_^]+33333310!!!!!!!��J�����������   �  �� 	 4@  
	LYLY ??+ 9/+3333310!!!!!!���F���������  w��'�  L@'LY LY  LY ?3+ 3?9/++ 3339333910!#   !2&#"327!�D��������g��g����úad��5�
.%�lb�Z�P�����1  �  f�  7@	  LYL
 ?3?39/]+33333310!!!!!!!f������6C5w�����=   B  ��  2@  

	
 ?33?3393333310!!57'5!��g������R�R��R�NR  �h�R��  @ LY 	 ?�+ 333310"'3265!iNPBfX6��R�Z��� ��   �  P�  B@
   ?3?9339333233339310!!!!7!P�������6z�X�h^����c���y   �  ?�  @   LY  ?+ ?333103!!�6Q��J�   �  ��  :@ 			  ?33?3993323393310!#!!3!!46##��	���Zo���	��{��u�X���^�J�1���  �  ��  6@
 	   ?3?39932393399910!!#!!35!��v��	���{R��}�P���v�  w����   (@  	LY	LY ?+ ?+333310 !   !  3 !"���������iQQe�պ�s��������z�mm��|�������   �  ��   4@		  LYLY ??+ 9/+333331032654&##!#!! �f��w����������
qlmh�������   w����   B@"
  

LYLY ?�+ ?+ 9333393310!#   !  3 !"緱`�s������iQQe�պ�s���������Q�wH�mm��|�������   �  H�   N@&

 

	 	MY  LY ?3?+ 9/+ 9333�293931032654&##!!  !�d����^���*��Jd����-bihX�y����݁�9��1   ^��� ' E@"! !  ()! !	LY	LY ?+ ?+ 9933993339310#"'32654&&'.54$32&&#"���괔�Ufm0]���P�r�qdu�JX^&S�͘���X B6NM+C>D?t�g��61�0&RB)=9Jb�   )  y�  &@  	LY ??+ 3933310!!!!!����sP�s���  ���^�  %@	LY ?+ ?3333310#  5!3265^�������5������N��!��������}     3�  *@		  	 ?3?3333393310!!!67�9����91@��J���M�(\�     ��  F@"
	 
 ?333?3333333933333310!!&'!!667!667!H���50�����1�1+�%�*
,�1 ),6�3����ݢ9�B3��7�QN�H      V�  D@ 		

  	 ?3?3933332339933933310!!!!!V����������:V;5N�5)�������+     ��  6@ 	
   ??3933939233310!!!1N����P\Z����/�   1  q� 	 ;@  
LYLY ?+ 9?+ 999333310!!5!!!q����V�D��� ��   ���s�  @ 	$ ?3?3329310!!#3s����������     B�  @  ??333310!!!������J�  3���   @	 $ ?3?33393103#5!!3����qT��   =�  -@    ?39/32333933103#����������J��}  ����N�H  � $ ?33310!5!N��R���  L��!  @ @	
�  /�93�210&&'5!�?�DV?��,�Be�   V��;u  " J@&""$#KYFYFY  ??+ 3?+ 9/+333392910!'##"&5467754#"'6323265f;M������®��e������v���j�aK����	1�Q�e���XZ�ze  ����   B@!!	  	 GY GY  ?+ ?+ 99??3339933102#"'##!36"32654&�����p3�1kpqhkt^ops�������Џ{��E���!������  \���s  *@GY GY  ?+ ?+333910  !2&&#"3267f��	ZH|>��X�KJ�=-L�%����/2��/$  \��q   @@!	!  	 GY GY  ?+ ?+ 99??3333910"323&5!#'#'26754&#"�����o
2�;hjumo}fqr23�}bf�쑥�!������   \��bs   F@#

JY JYFY ?+ ?+ 9/+ 933333910"!&&   32 !3267oan�r6�������/��e�bP��{qq{�R*3���*.�('   )  u  <@  FYGY  ??+ ?3+ 3339333310!!#5754632&#"!
���Ϩ��Ϟ{N\NA:y��y�RR��/�M<F  �ms ) 6 @ �@D==0) #B**7##A 4:KY	 &4)JY))&&?KY&-JY ?+ ?+ 3/+ /9/9+ 3_^]9333333393339310#''332!"&5467&&5467&&5463232654&##"32654#"m�0��7-/����������~z/FJFXg��/��'ym��ns�TqoSUVP��^�-K]��$,B���أ�e�[3@U)&�r���?HZN?0OM[jj[�  �  �  5@  			GY
 	 ?3??+ 933393310!!4#"!!3632��ϴ�r��1f����������%�Z���  �  �   $@		 


IY  ?+ ??333310432#"!!���SS�>��1��GO�^  �}��   /@IY 	 GY  ?+ 3??+3333310"'53265!432#"FuTFIMG1�p��SS���VT��)��k��GO   �  �  I@#


 
 ??39393?3339333393107!!!!Ņ9X�D��������1`�T����i���J�  �  �  �   ??3310!!!���1   �  Bs # M@&  
%		

$ GY
 ?33??3+ 39333933939310!!4&#"!33663236632!4&#"���QWuj���)-�n�Y-�n����QWpo�yy����^�MW�NV���'�yy��   �  �s  1@  		

GY
 ?3??+ 93393310!!4&#"!336632���V^�r���)3�r���yy����^�QS��   \���s   (@ 	GYGY ?+ ?+33331032654&#" !"&5 !2�m{zkl{zl����������1�����������̍�0���   ���s   C@"
 !
 GY GY  ?+ ???+ 99993333310"'#!33632"324&�p���+k���i��qhkt�e���;J������������!��R��   \�qs    B@!"	!GY GY ?+ ?+ 99??333399310%26754&#""3237!!47#otlo{�k����j�<��1�ۅ�%�������14PT����=kQT  �  ws  %@		


  ?29??3393102&#"!3366>)%5�����-4�s	��
����^�^s   \���s % ?@  '& 
FY
FY ?+ ?+ 993333339910#"&'53254&&'.54632&&#"���z�KU�Q�,lZ�y7��ʿ\T�L�W��z:L��! �(6`$-9&6\wW��X�$.I)<;5\x   /��7L  =@

FY GY ?+ ?3�+ 3993333910%27#"&5#5773!!wPpr�����X�9��I�#�3���f�����A>   ����^  2@	GY  ??+ 9?33333910!'##"&5!3265!�)1�s��1V^�r1�NU����syy����      �^  ,@ 		

	  ?2?3333393310!!367!��V?�$	(�?�V^��yl`�}��     �^  J@$
 


  ?3?339933333933333310!#!!3677!3667!7Vt�����0� �P�	.
�+������^���L�U��Va]H�,���  
  �^  L@$ 	
	   ?3?3933333339933939910!!!!���Z��Z��}������;#��d������   ��^  L@%		  GY  ?2?+ 3?39333333939310!367!#"'532677N�
 �G�'A�OL7AQy"^��Rpg[u����cd7   7  �^ 	 =@  
FYFY ?+ 9?+ 933399310!!5!5!!����B�
�����Q  ����  6@ !$ ?3?393333933339104&#52655463"&5�}~���cK��Jd��W\�XR>�}�FD�ռ"#�	��DF�}�  ��/�  �   ?/93103#����!  R��� " 6@  $#$ ?3?39333393333910#566554675&'4&'523"R��cKvs�Jd��Q{�}�-pr5�DG+Vk"�+FD�5sn��
TT�Ra   X'9}  7@    /32}/3333333993310"56323267#"&'&B7}6g�I�K�b5~6e�BxZ��C6�m  7@9�m%8  u���^   &@

 TY" ??+ 39333103!#"&54632��3��^ZVS[]QT\^�1%TVXRQYX  ����  D@#

OYOY  ??99//99++9939333210%$753&&#"3267#3�\�Ӳ��ZH|>yt�R�d���;���	A�$����-�=	�  R  j�  X@,	QY	 NY OY  ?+ ?+ 99/3+ 39939933399102&#"!!!!56655#53546���]�sNTw������gM����R�@YS�ۏ�N���,rd�����  q �!�  ' <@"	 " ()	% /3�2993�291047'76327'#"''7&732654&#"�6��[ji[��55}�_esT}�6�mPQoqONo�f_�57���Ynk\}�}33{�}]hMonNPnp     ��  q@8 	
  RY 
RY ??39/3+ 3�29+ 333339339933399310!3#3#!5#535#53!H9��������������<\Z�����ݲ��� ��/�   #@	   ?/99//9333103#3#����������   j��) - 8 U@*
." '3 9:6611**%%KYKY ?+ ?+ 993333993333333910467&54632&&#"#"'53254&&'&&7654&'yH=�߶��RD�NQJcr��}>?��˒Q�F�%ZP��߂tNe�%5%O�(T���T� 3.01J-@�m�S(iJ��O�)9u'03"J��Ch.9YD^1O ��    @   	 /33393�2104632#"&%4632#"&K@BKLA@K�Q<AMN@<Q}AFJ=<IF?FAH?=HA   d��D�  % 5 B@	&.&.67 *"2 ?3?399//339933993310"3267#"&54632&4$32#"$732$54$#"aj�9�9x����Ǖ�Jq�}�^��^��������Î������䢤������9����N�:���^����������ZƤ�壤������   /���  ! A@"#   ?�9/239329993939310'#"&546774#"'6632%326551+|Ju}��cQ�BB�c���D. MYc��n:@ujmm	u=� 2���F�&$SA$
   R ^�   \@+
	  
	 /3339/33393333333�223�233�210%Rs�������r������=�w����w��w����w�  X �9?  @
   /39/23310%#!5!9�����l� �� =�V�     d��D�   % 5 f@1 .&&.67			*"2 ?3?399//33939993399339393310###!232654&##4$32#"$732$54$#"�����/����B98E�`�^��^��������Î������䢤����?�pR������9BA6���^����������ZƤ�壤������  ���  �   ?33310!5!���   \�   @	  /3�2931046632#"&732654&#"\\�^\�]]�]�ɿYBBZ[A@[q\�^\�\]�ZǑ@Z\>?^\  X  9   6@

	 /33333/39333333310!5!3!!#5!��}����}��}�����{������  /J��  (@ 	  ?39?399333310!576654&#"'632!��y�f90(Qc{����^�i`J��dY2&(X���uU�u_  ;9�� % >@    &'	#	! ?3?39/399933933910#"'53254&##532654&#"'6632��^h�����{�XNp\SQ23/T9e>�g��7nOy�F�Zk55�49&2&(�/>� L��!  @@  	
�  /�93�210567!L�?V4�G��e4�2   ���^  ?@		 GY
 ??+ 99??33339339103265!#'##"&'!!�X^~r1�+*xX>h ��1�yy�����UU.,U���J  q���  /@ MY /3/+ 9/93�2910####"&563!����>T����\��P��3���  u)�}  @	  	TY /+33104632#"&uZVS[]QT\�TVXRQYX  ����    4@ 			 ?33/99|/9339310#"'53254'73���ND[H�N�JX��r�>S�=e   \JH� 
 *@	  	  ??3939339910#77'%3H�0Nm-�J�p_$*=�  9���   @  	 ?3�2993310#"&5463232654&#"ᷟ�������#AHH??HHA\��ŧ��Ŧdeeddcc  R ^�   Z@*		
   
	 /3339/33393333333�2�233�23310'7'7�������s�������s#�;w\\w�9�;w\\w�9 �� .  �� & {�  '�  <��� 	� ?55 �� .  �� & {�  '�   t��� � ?5 �� Z  �� & u  '  <��� 	�- ?55   =�y�^  ' F@$"  () 	%%TY%
OY# ?+ ?+ 3/_^]3939333103267#"&54676655#"&54632�Ylm9WYO�`fb�j��a�_5(ZVS[]QT\^Jb�MNX?9J:*�8E��l�iFJ=;VTVXRQYX ��    �s& $   C R �& +5��    �s& $   v �R �& +5��    �s& $  K VR �& +5��    �`& $  R VR �& +5��    �V& $   j VR 
�#& +55��    �
& $  PuX 	�# ?55      %�   o@<
  LY
LY


		LYLY ?+ ??+ 399//_^]++3333393339310!!!!!!!!!!#%������������3�z\���������`N �� w���& &    z  �� �  s& (   C��R �& +5�� �  s& (   v \R �& +5�� �  s& (  K��R �& +5�� �  V& (   j��R 
�!& +55�� *  �s& ,   C��R �& +5�� B  .s& ,   v��R �& +5����  As& ,  K�"R �& +5�� 9  �V& ,   j�"R 
�!& +55  /  u�   H@$

 LY  

LY
LY ?+ ?+ 9/3+ 333333333103!   !!#%4&##3#3 /��f��e�|�b��ң���Rd��������T���������� �  �`& 1  R �R �& +5�� w���s& 2   C uR �& +5�� w���s& 2   vFR �& +5�� w���s& 2  K �R �#& +5�� w���`& 2  R �R �& +5�� w���V& 2   j �R 
�+& +55  ��  @ 			  /2229333107'��՘-1���-����Ӗ�-���+����ј-�՘   w���   " 9@
 
 #$!LY!LY ?+ ?+ 9999339910 !"''7& !27&#"4'3 �����ŋZ�Z�iQƒT�X���8�Ti���3�Lhs����zA�l���m�F}h�����t�-���u�'�� ���^s& 8   C +R �& +5�� ���^s& 8   vR �& +5�� ���^s& 8  K �R � & +5�� ���^V& 8   j �R 
�(& +55��    �s& <   v �R �& +5  �  ��   6@  	MY	MY		 ??99//++33333310!#!!3232654&##��������6���Dd���|��������<izkh   ���h 5 T@+!!''  .7.//6! ''*3*GY3 /JY ?+ ??+ 933333339393310#"&'53254&&'&&54676654&#"!4$!2�*@J@*5B�i3��c�<5�@� RJ~bFFM>dt���%�&�@aL:0*4([bzN��"�$2{)3<*HwQ@j17P.<Qi`��s�� �� V��;!& D   C�  �+& +5�� V��;!& D   vm  �+& +5�� V��; & D  K�� �0& +5�� V��;& D  R
  �'& +5�� V��;& D   j  
�8& +55�� V��;�& D  P)  
�&& +55  V���u ( 2 8 �@E56  222	66&:-		9% #5 JY55 3JY)KYFY #FY /FY ?+ 3+ ?+ 9/+ ?+ 999/+ 933333939399910"&'#"&5467754&#"'6326632 !3273265"!&&1��HbŞ����YM��c���sB�x� �-��ĸO��Aq||�ex#��jeiuY����	TEBM�e�@A��锂�X�'(W[�ze��p| �� \��s& F    z�  �� \��b!& H   C�  �$& +5�� \��b!& H   vs  �$& +5�� \��b!& H  K  �)& +5�� \��b& H   j  
�1& +55����  �!& �   C�O   �& +5�� �  �!& �   v�E   �& +5����  �!& �  K��   �& +5����  �& �   j��   
�& +55  \���#  ' v@; )"( 		FY%FYKY ?+ ?+ 9/+ 99399993333939939910&'77 #" 54 327&''4&#"326�PHe�r�d�����������FC}�dzkyoxp{j5'�AL��h����������b�w���hl������ �� �  �& Q  R3  �& +5�� \���!& R   C�  �"& +5�� \���!& R   v �   �"& +5�� \���!& R  K  �'& +5�� \���& R  R  �& +5�� \���& R   j  
�/& +55  X �9�    *@

    /3�2�2339333105!4632#"&4632#"&X���JBBIJAAKJBCHJAAKd���LKNIFRNKMQGFQN  \����   # 9@
 
 %$!GY!GY ?+ ?+ 9999339910 !"''7& !27&#"4'326�����~lC�D��t7�:���=+?zl���&6zk1����-eid�04RlT���^H���Q<�2��� ����!& X   C�  �& +5�� ����!& X   v �   �& +5�� ����!& X  K1  �"& +5�� ����& X   j/  
�*& +55��  ��!& \   v=  �& +5  ���  ! D@"#" 		GY	GY ?+ ?+ 99??33339933106632#"'#!!"324&�2�i�����h��1�qhkt�e�QU�������̉>^�; �yxHN��!��R�� ��  ��& \   j�  
�,& +55��    ��& $  M XR �& +5�� V��;�& D  M
  �&& +5��    �}& $  N VR �& +5�� V��;+& D  N  �&& +5��  ���& $   Q{  �� V�Lu& D   Q�  �� w���s& &   v
R �& +5�� \���!& F   vo  �& +5�� w���s& &  K �R �$& +5�� \��!& F  K�  �#& +5�� w���f& &  O�R �& +5�� \���& F  O;   �& +5�� w���s& &  L �R �& +5�� \��!& F  L   �& +5�� �  us& '  L hR �& +5�� \��%& G   8o  �� /  u� �    \��  ( `@1
*&)	 #GYJY  GY  ?+ ??99//3+ 3+ 993333333399910"323&55!5!5!3##'#'26754&#"�����l�5
��;2���@hLnie�oSd TP�e3ǡ���T���{������� �� �  �& (  M��R �& +5�� \��b�& H  M�  �& +5�� �  }& (  N��R �& +5�� \��b+& H  N   �& +5�� �  I& (  O/5 �& +5�� \��b& H  O?   �#& +5�� ���& (   Q5  �� \�(bs& H   Q? �� �  s& (  L��R �& +5�� \��b!& H  L  �!& +5�� w��'s& *  K �R �(& +5�� �m!& J  K�  �N& +5�� w��'}& *  N �R �& +5�� �m+& J  N�  �D& +5�� w��'f& *  O�R �"& +5�� �m& J  O   �H& +5�� w�;'�& *   9  �� �m!& J  :Z  �E& +5�� �  fs& +  K �R �& +5�� �  ��& K  K 5� �##
  ?�5      �   Q@( 		LY 		 ?3?399//33333+333333333333103#!!!#535!!5!5!f�������ʸ�6C5��������w��-�����ô�    �  T@*  			GYJY	 	 ?3?99//3+ 3+ 9333333933910!!4#"!#535!!!3632��ϴs�Ϝ�1;��f���P���/�ǡ��S���� ����  .`& ,  R�"R �& +5����  �& �  R��   �& +5�� ?  ��& ,  M�$R �& +5����  ��& �  M��   �& +5��   }& ,  N�$R �& +5����  �+& �  N��   �& +5�� B���& ,   Qw �� +��& L   Q! �� B  �f& ,  O TR �& +5  �  �^  �  ??3310!!!���1^ �� B�R� & ,    -  �� ��) & L    MJ  ���h�R	s& -  K��R �& +5���}��!&7  K��   �& +5�� ��;P�& .   9 �  �� ��;�& N   9u   �  �^  A@


 ??39393?333333293107!!!!ύ:E�H����Ə��1F�n� ���Z��^�ۡR �� �  ?s& /   v��R �& +5�� �  ��& O   v�g� �  ?�5 �� ��;?�& /   9J �� c�;�& O   9�  �� �  ?�& /  8u�� �	 ?5 �� �  �& O   8 �  �� �  ?�& /   O/�p�� �  � & O   O��8    ?�  E@!	  
		  LY  ?+ ?993993993333333103'7!7!�Eq�6�u��Q�)�o���XĞ�X�       �  K@# 	 	
  ??99//3393333399 9999107!'7!�Fu���Gq�1�+�p�h�+�p- �� �  �s& 1   vDR �& +5�� �  �!& Q   v �   �& +5�� ��;��& 1   9 �  �� ��;�s& Q   9u �� �  �s& 1  L �R �& +5�� �  �!& Q  LN  �& +5��   �� ' Q �   �   ��R��  H@#

 LY ' ?+ 3?33?39932933999910"'3267#!!3'&5!�rS]Imv	��	���{��R[SN��}�P����m���J��  ���s  A@!

GY GY  ?+ 3???+ 933933910"'53254#"!336632=kM;<{��r���)2�t�ʼ����۫���^�OU������ �� w����& 2  M �R �& +5�� \����& R  M  �& +5�� w���}& 2  N �R �& +5�� \���+& R  N  �& +5�� w���s& 2  SBR 
�(& +55�� \���!& R  S{  
�,& +55  w��P�  # e@6    %$LYLY
LY
LYLY ?+ ?+ ?+ ?+ 9/_^]+333339333310!!#   !2!!!!!"3267&&P��&�-����S>=�#d����3������Az&#�	�ik�	������������  \��{s  + 2 p@:/0&&004 3/JY// ,JY)GY FY #GY ?+ 3+ ?+ 99?+ 9/+ 9333339399910 '#"&5 !2632 !326732654&#"%"!&&�������p�G������k�dQ��fm{zkl{zl�^|	�u����-OM�����*.�'(E��������syo}�� �  Hs& 5   v �R � & +5�� �  �!& U   v  �& +5�� ��;H�& 5   9 �  �� c�;ws& U   9�  �� �  Hs& 5  L 3R �& +5�� S  �!& U  L�  �& +5�� ^��s& 6   v NR �0& +5�� \���!& V   v
  �.& +5�� ^��s& 6  K��R �5& +5�� \���!& V  K�  �3& +5�� ^��& 6    zb  �� \��s& V    z-  �� ^��s& 6  L��R �-& +5�� \���!& V  L�  �+& +5�� )�;y�& 7   9) �� /�;7L& W   9� �� )  ys& 7  L��R �& +5�� /���(& W  8  � ?5   )  y�  F@#		  LYLY ??9/3+ 3+ 39333339910!!#53!!!3#������sP�s��T�b�����  /��7L  ]@/				 FYJY GY ?+ ?3�9/3+ 3+ 39933399333910%27#"&55#535#5773!!!!wPp4�I����X�9����I�#�������f����ƔA>�� ���^`& 8  R �R �& +5�� ����& X  R1  �& +5�� ���^�& 8  M �R �& +5�� �����& X  M/  �& +5�� ���^}& 8  N �R �& +5�� ����+& X  N1  �& +5�� ���^& 8  P �R 
�& +55�� �����& X  PN  
�& +55�� ���^s& 8  SR 
�%& +55�� ����!& X  S �   
�'& +55�� ��^�& 8   QH  �� ���^& X   Q�  ��    �s& :  KqR �+& +5��   �!& Z  K    �+& +5��    �s& <  K R �& +5��  ��!& \  K�  �$& +5��    �V& <   j R 
�& +55�� 1  qs& =   v NR �& +5�� 7  �!& ]   v  �& +5�� 1  qf& =  OR �& +5�� 7  �& ]  O �   �& +5�� 1  qs& =  L��R �& +5�� 7  �!& ]  L�  �& +5  �  ?  "@
  GY  ??+ 333310"!4632&P�ϼ͞xG\-��\���/�  ��/�  I@$  

FYGYGY ?+ �+ 9/3+ 39333333910#"'5325#5754632&#"3#鼰kM;;}���pHR?m��y����q�RR��/��F�     ��   ! - w@;!  "(@((		/.LY		+!%  ?3?3�9�2239/+333393393�293�2999910!!!&54632&'5667!4&#"366�/���j��l���+�pm�1fVDpL.jV�l6**7V&2�U>��J��#:Wn���-!�EG����*xt7��-33-\3   V��;�  " , 8 D ~@?'(#,##3--9?3??""FE,66'<0B@KYFYFY  ??+ 3?+ 9/+ �2��39333392993�293�210!'##"&5467754#"'63232655667!#"&546324&#"326f;M������®��e������v���j��.jV��ώpp��qn��6**710*6�aK����	1�Q�e���XZ�ze/*xiD��l��nl��i-33--44 ��    %s& �   v�R �& +5�� V���!& �   v�   �A& +5�� w���s& �   v1R �+& +5�� \���!& �   v{  �,& +5�� ^�;�& 6   9� �� \�;�s& V   9�   ��!  *@  		�  /2�2933333310&'#567!T�MN�˽Ce�H�]SQ_�p4�F   ��!  *@ 	

	 � /3�2933333310!&&'5367T���lw˓RT�!T�2/�{]SWY ���  �    /39�10!!��Z��  ���+  &@ @o  � /3�]293�210#"&'3327�ܦ���/UU�+����/6}  ���  �  	
 /39�10432#"���SS���GO T�J�    @				 /33/]39310#"&546324&#"326J�pp��qn��6**600*6�l��nl��i-33--44  
��    � ?3/9910327#"&54673�-#7<RJq�Lh�FN�*(�gCvMBm   ��  4@@ o� /�]99//3393�210"#663232673#".�9��v)OMJ$9��t)OMJB56��!' 46��!'!   ��! 	  (@
@	  �
  /2�293�2�2�2105667!3567!�>o- �J�8-�l�U�)5�6�m+�Q  ��D^  @
   	
 /�93�210667!#�5Nm��6�T��   ����    2@  !	 /333�999393�23104632#"&%432#"&'667!#�G:9JJ9:G#�9JJ9<G�':��}G@@GDAAD�@GDAAN1�@������  ��& $  T���� �2> +5 �� u'�{    B����  �� ' ( �  T���� �2> +5 ����  �� ' + �  T���� �2> +5 ����  �� ' , �  T���� �2> +5 ������9� & 2R T���� �2		> +5 ����  � ' <  T���� �2> +5 ����  l� &vZ T���� �$2$$> +5 �������&�  U�   �"& +555��    �� $  �� �  �� %    �  T�  @ LY ??+33310!!T������ �J� �� 9  
�(  �� �  � (  �� 1  q� =  �� �  f� +    w����    G@%

LYLYLY ?+ ?+ 9/_^]+33333310!5 !   !  32654&#"3�����������iQQe�Ͽ�������f������z�mm��|��������� �� B  �� ,  �� �  P� .       3�  /@  		 LY	 ?3?+333393310!!!&&�3�����R�����
<�>�)����Jo��� �  �� 0  �� �  �� 1    R  ?�    C@#

 LY   

LY
LY ?+ ?+ 9/_^]+33333310!!!!!���R��d��w�=��H�   �� w���� 2    �  =�  #@  	LY ?3?+333310!!!!!=���������L� �� �  �� 3    N  y�  S@)

	   	
LY  LY  ?+ 99?+ 93993339939310355!!"'63!N��5��J3���#�-��
����=���  �� )  y� 7  ��    �� <    \����  " + V@+ ""+		-', ++MY!$$MY		 ??99//3+ 33+ 333339333331032654&##5#"$546$335!32###"33�����)����衏�55�������)��������������������������9������    V� ;    m  ��  @@  MY ??339/3+ 33333933310 !#!#  !33!3265!�����3��3����"����#������L�	��!�������  7  �   W@+
"!	  LY		LY ?3+ 3?+ 993333333333993310"!!&54$3  !!654&%�Ą���s���<�?y��v�}��������H��]AƸ��������`��H����� 9  �V& ,   j�"R 
�!& +55��    �V& <   j R 
�& +55�� \�� ^&~  T1  �3& +5�� N��%^&�  T%  �/& +5�� ���^&�  Tw  �& +5�� ���^&�  T�   �& +5�� �����&�  UD  �*& +555  \�� q  * K@&)",	+GY%HY%)  GY ?+ 93+ ?+ 9?3333339910%26754&#""323673327#"&'#ovko{�k����v�2+� 'T [pv"nߏ��������00TT^7a�h��v
�
MZ�  ��   ) X@,"
''

+*"##"GY## GY GY   ?+ ?+ 9/+ 9?333393339102#"'!4$"32654&##532654&����������~����0�<�|�H5cnnй������?��4�������'|pns�mf\d  ��^  <@ 


 ??33333333939310!47!3667!���8,�V=�B9�=�c-6�V�R�>�I,�Y���t��  \���  ) k@5 !!$+$*$$!''GY !!	FY  ?+ 3?99323+ 9933333993393910&54632&&#" !"$5464&'326����oэy\�XIJ������������C_i{�xioz�����-B�-76.6iF^�������Ҷ���]�:#�~e}�   N��%s & b@2 ##('&&JY&&&
  FYFY ?+ ?+ 999/_^]+ 933333933910#"!267! $54675&54632&&#"3H���g�Y������瀐���s�X^w�Mqn����AH}-)�M��k�
1э�.&�026B7   \���   P@'   "!!FY " ??+ 99339333333399310!6654&'$4 %#!5! ���EOOf�H4�3��V����'IgA��%��]�/ )M~���
߶�����JZ5!}   ���s  2@  		

GY
 ????+ 93393310!4&#"!336632���V^�r���)3�r���yyy����^�QS��  \���+    ?@   FY		FY	FY ?+ ?+ 9/+33333310 !   !  267!"!&&���������	��uk�7iyln	�i�k�u�����i�5���������  ���^  !@	GY	 ?+ ?33910327#"&5�I<Qpm���^� A>#�3�� �� �  �^ �    ���! " b@2"" $"  #HY
HY
  ??+ ?+ 393333339939393103'&&#"5632327#"&'&'#�#$\_24OWs�s3%L7!$r'n�)r+.�!\ZJ�F����hb
�lwC�4�L� �� ���^ w      s^  *@   ?2?9323393310!36!!9�Esf4X����^����+� �����  \��� . e@2%&&))#	 ##0  /!++/JY&"		JY  ?+ 33?9/+ 9333339933339333104675&5467##5!#"33#"!6654&'&&\��ۇ��C$K�끓����/a������EOOf���~�6
4�k�%�҉u_R�{{GU5!}f��]�/ )&��� \���s R    ���^  B@!		FY GY ?+ ??+ 333339933910%27#"&5!!#57!#C?)6���������6�#���B��u�f���31   y��s   /@   		

GY
GY ?+ ??+3333310#"'#! 32%"32654&��ښ�������qj+t<rca/����M�`��/��������++����   \���s  5@  "GY ?+ ?33333333310 !2&#"!654&'&&\"��X�h~r2d�����͔Rc���H=P�B��J^9#�j���a$+*�  \��`   ;@	  	FY	GY ?+ ?+ 33333393310#  !!!32654&'#"��������w=����wvtx;D2��ے�z-?߾�����o�S�   )�� ^  5@ FY	GY	 ?+ ?+ 333399310327#"&5!57!sI<Ppk�����'y��A>#�3��f�   ����^  -@ 	GY  ?+ ?333333310 !32654&'! ����2ir}r+3(��`������kַ��v����   \��w 	 # P@)##

  %$FYFY"
 ??3+ 3?393?+33339333104&#"66$ 5474632 �^Z9@��������nx�ZJֺ� ���N��Oa����a�#����z�y��4����������   ����m   X@,"!HY HY  ?+ 3??+ 3?93333333339333102!327#"&'!&&#"56�ZrP)J3�9�F=14Un}�4h������F88;rm3q{����%@5���F��u`F>�  ��F  A@ 		 FY ??3+ 3?3?33339333106654! !$ !�PN����������#�������<���������&�	!3�ŭ�;  m��{^ ' ?@
%%)

(!FY  ?3+ 33?39/333393910"&'##"47!3265!3265!�z�)
.�w��0@%}c`SLLT^d}%@1�iind.�����Ѥ�t�'�هs��3���������� ��&�   j��   
�#& +55�� ����&�   j'  
�+& +55�� \���^& R  TB  �"& +5�� ����^&�  TN  �& +5�� m��{^&�  T5   �0& +5�� �  V& (   j��R 
�!& +55  )���  R@*			 LYLY MY  ?+ ??+ 39/+3339392910"'3266554&#!!!!!!2mtWcI62S_������Z�J\���& +D7YG�^�����ν��� �� �  Ts&a   v �R �& +5  w��#�  ?@ LY LY	LY ?+ ?+ 9/+33339910"!!327#  4$32'&J��y��ɼ��j�z�����M��loW�ɿ����M��(#�j�W�70�%<�� ^��� 6  �� B  �� ,  �� 9  �V& ,   j�"R 
�!& +55���h�R�� -    ����  # Q@*
 %$ #LY  
LYLYLY ?+ ?+ ?+ 9/+33399333103 !!!'"'5326!32654&##�s'�����i��>_��T@:35>7[ X^����H���������c��aW�Hefc[   �  ��   R@*  LYLY	LY ?+ ??39/+ �+33333933310!!!!!!!3 32654&##������i�#��6�5s'�X^����H���w�����=����aefeY  )  �  F@#	  	LY
	
	LY
  ?3?+ 39/+333933910!4&#!!!!!!2�FP������Z�J���YG�^�����Ѻ���� �  `s&�   v �R �& +5��  ��9�&�  6 ^R �& +5  ��V=�  2@	  
LY' ??3+ ?333339310!!!!!!!=�T���R65�V���L���    �� $    �  ��   ?@ 
   LY  LYLY ?+ ?+ 9/+333339103 !!!!32654&##�z8���V���h����O����7�� �HefeY �� �  �� %  �� �  T�a    
�V��   Q@(		'  LYLY ?+ ?+ 33?33333939393103!3!!!!
q��)T����l��� �];"CO�L�T��V^�� ���� �  � (       ��  T@(	 


		   ?33?339333333332333393333310!!!!!!�?�!�@������������<��<��B�����  ^���� & J@%  !(!'MY
$$MY$
MY
 ?+ ?+ 9/+ 93339933910! '3 54&##532654&#"'6$32�ȫ���������^�nq��{�ԅ����}��`������O-3�ah�XfKYw�SM�  �  ��  ,@			  ?2?39933339910!3!!4#!�
�s���Z����>��V�J���� �� �  ��&�  6 �R �& +5  �  `� 
 4@		  


 ?3?39333233333310!!!!!`������6J������<��B   ��=�  1@
  
LYLY ??+ ?+3339310!!!'"'5326!=����>_��T@:35>7[ �����c��aW�� �  �� 0  �� �  f� +  �� w���� 2  �� �  =�n  �� �  �� 3  �� w���� &  �� )  y� 7     ��9�  E@!  
LY ?+ ?39333393939310#"'3267!379�<U�̒}lX�Sf"�Hh
.���êS
$M_��2� �� \����s  ��    V� ;    ��V�  4@	  
 LY' ??+ 3?333339310%3!!!!!=�����65��`���L�  m  �  -@  LY	 ??39/+3333310!!#"&5!3267!�ʚ�]��5buR�w654&ɶ\��jk!)�   �  ��  5@ 		
 LY ?+ 3?3333339310!!!!!!��5��6�8��J��L�   ��V��   >@ 		
 	LY	' ??+ 33?33/3333339310!!3!!!!!��5����"6�8���@�`���L��J     u�   A@!	  	LY		LYLY ?+ ?+ 9/+33393310!!!!3 32654&##u�����V���{8�/h����P��������aefeY   �  �� 
   A@   LYLY ?+ ?39/+ ?333339310!!!3 32654&##!!������p6d5�NQ����C���5��������beffX�y�   �  �� 	  2@  

LY
LY ?+ ?9/+3333310!!!3 32654&##����V6z8�0h����O��7�����aefeY   H����  I@&			LYLY LY ?+ ?+ 9/_^]+33333910"'63   !"'3267!5!&&)c�]b��Ec��������	��x��8'�g�q�����}KM�����   ����   Q@+	  		LYLY	
	LY ?+ ??9/_^]+ ?+3333393310 !  !!!! !  3 4&#"������������6"I<N�+��L��������wM>�����!3�x�������� ��  ��   Q@(  	  MY		LY	 ?3?+ 9/+ 933339339310!&&54$!!!#"33������|���ʙx����1���2ю���J1�Vdap �� V��;u D    \���%  # D@"%!!  $FYGYHY ?+ ?+ 9/+ 933333310 %6%36632 !  2#"\%7�,#���~|=5�d����� � ��1��6kY����5(��1P�{RX������ox+#2Q)��   �  �^     N@'  "!JYJYJY ?+ ?+ 9/+ 93333393910#!!24&##3264#!326�qnw�� ���=����ff��ae�� �ad9Z�c��^���B;��If�8   �  �^  @ FY ??+33310!!��-��^���^  �o1^   I@% 
FY#	FY	 ?+ 33?3?+333399339310%#!!!36!3\�WMw�����^`������������op��$���� \��bs H       �^  R@'

 	  ?33?339333333223333393333310!!!!!!��;�d����V���V����d;?������7��7��F  N��#s ( L@&'

#*)('('JY(( FYFY ?+ ?+ 9/+ 933399339102654&#"'6632# '532654&##5���jzM�PZw����߉u�����V�`����v�8=66&!�-'���9
"}ef�VE�(.C>DA�  �  #^  ,@
 ?3?39932339910!!47!�o������^�FF�����w���^ �� �  #?&�  6 �   �& +5  �  �^ 
 6@ 

  ?3?39333233333310!!!!}P�E����7��1^����7��^��    ���^  5@
  
FY
HY ??+ 3?+3339310!!!#"'5326!����� \�|jD119M=Ny����� ��O  �  !^  :@   ?33?3993323393310!!#&''!!>!!��6+���+1����3	!%,��q>�l��n�D��^�#M�G��n�   �  �^  3@		

FY

 ?3?39/+33333310!!!!!��1���V��^�R�����3^ �� \���s R    �  �^  #@	FY ?3?+333310!!!����k��^��y��^ �� ���s S  �� \���s F    /  =^  (@  	FY ??+ 3339310!!!5=������^���y���  ��^ \    \�'    P@( !  FY 	FY	 ??3+ 3?3+ 3?333393333310  !$ 54 %!4&'66�>����������4&�Ś���X����d��������/��%����������d� �� 
  �^ [    ��od^  4@	  
 FY# ??+ 3?333339310%3!!!!!�����N1�2����^��y  {  �^  -@

		FY

 ??39/+33333103267!!#"&5��X�M1��j�U��^�g�( ����8.���  �  !^  5@		  
FY ?+ 3?3333339310!!!!!!!!�1w1w1^��y��y   ��o�^   >@		  
 FY# ??+ 33?33/3333339310%3!!!!!!!!�����1w1w1�����^��y��y��     f^   A@!

JY
FYJY ?+ ?+ 9/+333933103 !!!54&##32��������5gh���^�P����y��A:��   �  -^ 
   C@!  JY  	JY ?+ ?39/+ ?3333393103 #!!4&##32!!ѓ ����11Xhg�����1�����^�A:���^  �  �^ 	  2@
  JY  JY ?+ ?9/+33333103 !!!4&##32������1�hg��������^�A:��   J���s  ?@ 	
	JY

 FY FY  ?+ ?+ 9/+33333910"'53267!5!&&#"'663   �҆��nx
�Z�kdw�VK�^ ��E�P���{|?�#-��������  ����s   I@&   		GYFY	
	GY ?+ ??9/+ ?+3333393310 #"$'#!!36$32 32654&#"����������1����%bqobcpob1�������3^�R�������������      ^   M@&

 JYJY ?3?+ 9/+ 933339329310!!&&5463!!#33#"J��-lo���Ϩ�nY��KU�-�s�����bFOI�� \��b& H   j  
�1& +55  �� & j@6$$$(''  GYJY    GY  ?+ 3??99//3+ 3+ 93333399339910"'53254&#"!#535!!!3632=kM;<{^Vs�Ϝ�1;��f��ʼ����nn���/�ǡ��S������� �� �  �!&�   v  �& +5  \���s  A@!	JY FY FY  ?+ ?+ 9/+333339910   !2&#"!!3267�����!��X�kis��[ngO�f�#* J�Az}˃}$,�I �� \���s V  �� �  � L  ����  �& �   j��   
�& +55���}�� M     ���^   Q@*  	!	 JY FYHY JY  ?+ ?+ ?+ 9/+3339933310!##"'5326!32!4&##32-� \�|jD119M=#�����ba���y����� ��O�P����`A:��  �  �^   Q@) 

	FY  JY  JY ?3+ ?39/+ �+3333393331032!!!!!!!4&##32^�����;����1\1Dba����������3^�R��A:��     �  V@+  			GYJY	 	 ?3?99//3+ 3+ 9333339933910!!4#"!#535!!!3632��ϴs�Ϝ�1;��f���P���/�ǡ��S���� �� �  �!&�   v �   �& +5��  ��?& \  6�  �& +5  ��o�^  6@	

   
#  FY  ?+ 3?3?333393103!!!!!�1�2�x��^��y���o�   �  }�  #@	 LY ??�+333310!!!!!�����q�6��   �  ��  #@	 FY ??�+333310!!!!!����^1�� ��    �s& :   C �R �&& +5��   �!& Z   C �   �&& +5��    �s& :   v�R �&& +5��   �!& Z   vd   �&& +5��    �V& :   joR 
�3& +55��   �& Z   j �   
�3& +55��    �s& <   C�|R �& +5��  ��!& \   C�Y   �& +5  R���  �   /333105!R\���  R���  �   /333105!R\���  R���  �   /333105!R\��� ���1N��    @  	 /39/3233310!5!5!5!N��R��R�1���   ���  @
	  ?�33�210'673'e5�B#�[q���   ���  @	 ?�33�210#7�2~�E����(�   ?��� �  @	  /�33�210%#7!�4|�A$����
�   ���  @
   	 ?�33�210#&'7?%@�;a��� U  �w�   %@  ?3�233�2�2�210673!%673!�e5�B#���e5�B#���[q���[q���  �w�   #@	
 
 ?3�233�2�2�210#7!#7!�2~�E�2~�E����(����(�  ?��� �   "@	
 
 /3�233�2�2�210%#7!#7!�4|�A$�4|�A$����
����
�  {  �  N@%
	  
   ??9/3339933339333993310%!5!%���7��7��777L��B����_   {  �  }@>	 
 		  ??99//3339933333993333339333933333310%%!5'75!%%oK��7��8��L//��L87K��/-���y����x����   b��)  �  	 /�93104632#"&b��������욣�����   u��b9   # ,@   $	TY!	 ?33+ 3333�2�21074632#"&%4632#"&%4632#"&uZVS[\RT\GZWS[\RU\HZVS[\RT\�TVXRO[YQTVXRO[YQTVXRO[Y   ?��
 � 	   " - 7 B C d@1.>8388E
 D)###C5  @+1;& ?3�2???333�223/33�29333�29333�2103254#"#"&5!2%#3254#"#"&5!23254#"#"&5!2;-2``2-�����Y������+�-2``2-�����Y��P,2``2,�����X���5 }��{}��������J��}��{}�������}��{}�������j �� ���� 
  �� ��B�     R ^�  0@  /39/39333333�210Rs������=�w����w�  R ^�  0@   /39/393333�23310'7�������s#�;w\\w�9 �� u��� ' H       �w  ��  @  ??33�210#����+��J�   f�
�  *@	 	 	
 ??39�299339104&#"#3363 D<9ZHǢI���L@`q���Te��/  #  '�  V@+ 	RY NY

NY
 ??+ 9/+ 9/3+ 333333333910!!!#53!!!!�<���ϕ�o��������������  R  j� % y@=
" &' ! RY
!RY NY OY  ?+ ?+ 99/3+ 3�2+ 3993399333333939102&&#"!!!!!!5667#535#53546���]N�EPLg��g��FJ���dK������R�#VVq�s�Jl'���*jU�s�s��   �����   ) q@< #''%	+		+ *QY NY&#&QY#!PY ###NY ??+ 99//3++ 3+ ?+3339339933391032654&##!#!! 27#"&5#5773!!�B��~�T����5��u�NSa�����X���Hhumh���������#�3��>lg�����<C   B���� ' �@H%%$	$$$)(	RY"% " OY"NY ?+ 3?+ 399//_^]3+ 33333333393399999939910"!!!!!27#" '#53&57#536 32&&#z���^c��3��t����)�vt�%D�bExɍ��#/!��9� ;
�'5��R�#  ?���    0 Z@,  .%$
$
*2*1%''".,," ???3�2?�2333333399393339310##"&5463232654&#""&54632&#"327���+�������->GD==DG>�Z����ud7f@II�tZO��J�����Ĩ��Ǥdeeddcc8����2�)f_�+�-   )����  $ F@ "%&""  /3/9/93399399333339310%2673#"&5556746324#"66�<M����̶bT�ţ���Z5'X^�cfܽ��1���������p���L?��'�  �  ��    + ^@-	   &-,#) ?333?99399//333333�293999910!!#!!3&5!5!#"&5463232654&#"������J�
����������"AIG@@GIA���������}�J����Ƨ��ǣdeeddcc  ���   _@/ 

 ?33339/33399393�93393310##5!###33#7#}��4�?��������<����o�^����/�y�� �� 7  �v    f���H   B@ !  /2/9/39339993339310"&546632!3267&&#"y��������1�R��QHbٓ2�X�z#�����������5Fi�)�|�5Bu���� :���� '�   '@��� {�  � ?555 �� ;���� '�   '@��� u   � ?555 �� Z���� '�   '@���=  � ?555 �� C���� '�   '@���?  � ?555   ;��b�  # A@!" " %$FYGYGY ?+ ?+ 9/+99339910#"&54632&#"63227&&#"b��ܼ�ӕ��iT�6�V�����g� N5FsI����@��Ϯ6�)�69Z���6�44l�p�   9  
�   /@


LY ?3?+9933933107!!!'&9�^��/i(�Z�$�
����W��4 '�  ��7H�  "@ 	LY  /3?+333310!!!
������7}����  )�7�  L@%	 
 
	MY 	 	LY  /+ 9?+ 939993333931055!!!)?�������H�7�B����o��   Xd9?  �   /333105!X�d��  %����  6@ 
	 /3/9/33339393310##5!3�����E�������l   q{7#   ) N@$"''  *+"" $$*  /3339/3�293999933933310#"'#"&5463263227&&#""32654&7���{;�O�����s}�����XN&P28EEjWQPZ8DF͎İM]���������DCM<<I��P9:K    �L  "@

   ?3?3339310"#"'53254632&�3<ĸmV[Cn»mVYHA���)�'����(�&�� X]9B ' a   � a  �6 ���L�  > +5  X �9  Z@- 

  /33333�22323333399392910'7#5!7!5!3!!1�Y�PP�`��\���O����T�۪�V�٪�  V  9=  
 :@	  		

  /2/9/339333333331035!5V����T�����������   X  9=  
 6@		
  	

  /2/39/39333333331035!	5X����T�����>����J   X  P�  	 B@ 		  
 	 ??9333993393333310#3P�=r�=�r������!�����f�g�� )  � & I    L  �� )  � & I    O    h�3?  @  
 /3�293�210#"&'!32673����Ysec?����gS[_ �}��^  !@	 GY  ?+ 3?33310"'53265!FuTFIMG1���VT��)�� ^��  @   	
  ?�93�210667!#^'PV��1�@�� ^�;���  @
   	
 /�93�210667!#^'K[��V1�@��  N��!  @   	
� /�93�210!5673�'��NX�1�@��   )5��    @ 	! ?3?399331032654&#"!"&5!2%-12..21-�����X�� }|�{{}�3����   J�� 
  B@	 		  ??9/3392999333399310##5!533!547�}�����}��	5ᗗ�A�ͤVbl�  T9��  L@$  ! ?3?39/3393993939393102#"'53254&#"'!!6������d2�7�WQ?8m%��8����4� *�?@+���   -5��   8@		   	! ?3?39/39993399310#"&5%366322654&#"ٯ���#C��YJt���;><9�Dm�������5�W+/���G?6DjBT   ;J��  (@     ??399939310!5!�T�M���J����)  -5��  ! - F@!%+%+

./  ((!"  ?2?393939933993399102#"&5467&54632654'"6654&���CLKB#����GW�:9;<�eu+-4&&2*�yi?d+*=I,u��xAj.Y~hz�n-99-Q,,�/)22+/  +9��  " 2@    #$! ?3?39/3999339210#"'53267##"&54632%"32654&���I613��G~z�������5B8;7FD3���p�b�����#GA7A?+CS  T����       # ' + / 3 7 ; ? C G S [ k t | �@�@<0A=1 NTcpp``ll�zggv�vkkH�HX���XTE)%
D($	���}}kduullvvkVKKkk\ZQQ�t\\-$1'2D=G>(A+B	  BA>=21,84 95! /333333333/3339333333333333339/333/39/3/339/393/399333333333933939332933333333333310!#%5!#533!5353!5!!5!5!#3#35!#35!35!#35#3#3#"&546323254#"%32##32654&##32654#"'53253T/��0m� o��m�I�����mmmm���0oo�w��oooo�mm�����~��s�����mp.,;0m^�{B.$*/;J1%Z^4+V}i�0o��o����/�mm���mmmm�oo���;mm�Joooo�/y�hI�����������aCS1DD8QYb" "�+%J��
fV��r_c  T���   * X@)%+,(("""  //99//3333/9933999939333210	54676654&#"63232654&#"���T�V�,AgI��O�GR�Z?>1HT;GFBIHCHE�V�W��/2A1R~X��8*�P:/5K6DpJ;��?HI>@IH���}��!&7  L��   �& +5�� ���    )���)  6 v@="4	11* ..((678GY44 	* *FY  11FY1%FY ?+ ?+ 9/+ 339/+9933939399333310&&#" !"&54654&#"'63232655'&$&54632 3��e;F��������*0L��Zga\����Ȣ���,�ߩ�89r��+-������5i+*�V^X?�GKO��!tь�������     �  F@"    

MY ?+ 3??9333333393310>32&#"!!}>xhu_UB,(5C�6���PT���B�+'`�����/�  3���^  ( l@5
##  *)!!FY&FY  ?3+ 39?+ 339/3339939393993310"'##"547!57!!4'!32655!326F�S
R���?������?�3@��>\gTLLTg\�����f�Ѳ�����ɰ��s����s��� �  �u& 0   v�T �& +5�� �  B!& P   v�   �,& +5��  ����& $   [s  �� V��;u& D   [   ���r��9� & 2R  \��    X��N��    @ 		 /39/393�210#"&546324&#"326N�pp��qn��6**600*6��l��nl��i-33--44  yh+�   1@  ?�2��9393�9�2�210467#"&767!#y��IE%-%?BCJZ**���RpJ%%-J'C�W^� �� )   & I   ' I    L/  �� )    & I   ' I    O/    w���    H@#   		LY@	LY ?+ ?�+ 993/3393339910 !   ! 65!3 !"���������jRZ�]-$�{=�պ�s���������z�mk��=���2��������.  \���  " # H@# $  #

 GY@
GY ?+ ?�+ 993/3393339910 !"&5 !265!32654&#"��������p�G�-W�i4��m{zkl{zla1���̍�0EE-���k}���������(  ���)   9@
@LY ?+ ?�39/3/333�23310665!#  5!3265^JF- k���������5��������j��g�¢�!���i������J  ���s   J@% @KY 	GY  ??+ 9?3�9/+/3393�23310!'##"&5!3265!665!3�)0�s��1V^�r1GN- l����MV����syy��u�t��f�������W!  C��  ������!  v��  ������ R�   ������  � /��23910#'6654&#"56632���
�K6*"AJi)��Ϝ)G�3% "�
o  ���R�%�}  � /�10432#"�٦�TR��疖GN�� �  s& (   C�zR �& +5�� �  �s&�   C TR �& +5�� \��b!& H   C�  �$& +5�� �  #!&�   C  �& +5  w��=� 2 b@1++((00

4#3))   MY-&&LY ?3+ 39?3+ 3339/33339393310"'663   !"&'#   !2&&#"327!3254&�'ZDl@�K)����t�MM�t����)J�BlD[&����SU6Hl����!-�1<�������cHKKH�xRw:3�-!�����E��tE	���    �^  U@) 		


	

  ?2?33?3993333939339993310!!367!36!!��u@�!<mX�>g]4���^�d�S�l����"�����}��        O@(
 

MYLY LY ?+ ?99//+ 3+ 3333333339103 !!!5!5!!32654&##5{8���V�  5y��i����Pd����7d������efeY     '   J@&
 

FYJYJY ?+ ?�39/++ 3333333339103 !!!5!5!!4&##323�������1g9hg���yˤ���y������A:��   ���R� " U@, !$#LYLY!LY ?+ ??9/3+ 3?+333399339910!3267#  #!!3 !2&&#"!f��Ъa�rh�w�������6�,|$��dZ�W��dw��(%��(#N=�����:g�':��  ���s   W@-
"	!FY	FY		 FY  ?+ ??9/3+ 3?+333393339910"$'#!!36$32&#"!!327�������1��[�MV�xdk��Z	ts������3^�R��,$�?qp�~P�E     ��   E@#
	  MY	  ?33?39/+3333999222210!#!#!!!'��d��f���-{/�u9�w��w����DdYE4      ^   L@% 	

 JY ?33?39/+ 3333393333999910#!#!!!!'&'bN��P����o����#H��Z��Z^��uP�W]   �  
�   t@9	   		LY  ?3333?9/+ 3393?3333339/39333399999910!#!#!!!!!!!'&'��d��g��������6��{/�u93\
w��w��w�����C�Dd��'4  �  7^   x@; 


 FY ?3333??39/+ 339333339/339333399999910#!#!!!!!!!3&'oB��B����������n����#�`��5��5��3^�R�����DI   )  F�   �@B 	   LYMY	  ?22?9/33+ 39333+ 93333393339393393931036675!!&&'!!)�:��������9���{)TC��GV({���ų�$Ջ��+%���;�|d��qe{�{9     �^   �@B 	   JYJY	  ?22?9/33+ 39333+ 93333393339393393931036675!!&&'!7!u(}[��4��Yy*t��^8/��6<^h���Z}� mjj�� �{��'MB�?�
DN����  �  m�  " # �@V"  !
    %	$#%""LYMY	LY		   ?333??9/39/++ 39333+ 93�3333233933393933939310!67!!!!5!!&&'!!P�,3����6C������9���{)TC��GV({������3���������+%���;�|d��qe{�{9�L  �  �^  " # �@U"  !
    %	$#%""JYJY 		FY		  ?333??9/9/+ 3+ 39333+ 93�3333233933393933939310!67!!!!5!!&&'!7!#u ������ 3��Yz)u��^</��6<^h����4ZU�3^�RDjj�� �{��'HH
�?�
DN�����q  )�/�� I �@L2(77
DBB@@FFF?=

(.K=((J3232MY33@DD 	 @F@@:MY@%MY%'+MY ?+ ?+ ?3+ 3�_^]29/9/+ 93333399933333339102&#"!"32772&&#"&54676654&##532654&#"'667&'53>�J0>]_����������\b)�Yh��Z6�����ì��{�ԅ�Ͼ�S�w`��6�NWe���"��������')X)�����enah�XfKYw�6Lw�(�dN.   �/#d L �@Y4*99
GEECCIIIB@
 
*0N?@@**M?<C<JY5454JY55GGC  KY @IC$FY'FY!!''.FY ?+ ?3/+ 9+ ?33�+ 39/9/+ 9+ 333333399933333339102&#"!"327632&&#"#"&54632654&##532654&#"'667''53>{H3"6TJ~�ih�o����laKYUON0�V4D�|���턄��vp��jzM�PZA>]W�9�RVcd�o"�a_{
"}e��'44*)�����@ADA�8=66&!�!
l_)�fL- �� m  ��u  �� ��F�    w����    ?@   LY		LY	LY ?+ ?+ 9/+33339910 !   !  267!"!&&���������iQQe�H�������������z�mm��|������ۮ���  \���s    ?@   JY

GY
GY ?+ ?+ 9/+33333310 !"&5 !2267!"!&&�������������ap�>ndbp�m1���̍�0���� tttt�qppq      ��  A@ 

  LY
 ?3??+ 933333393310"!!67>32&B.@*�����9!+6�7\xVtF3�Gv����s������K'�      �f  @@		  	GY  ??+ ?3933333393310!367>32&#"!?�2,{3LkULH+' 3����^���Oo|X�j1�,7����    �s&�  v'R 
�)& +55��    �!&�  v�   
�*& +55  w�
��  " . k@7		0) 0#/ ,LY &LYMY  ?2?+ 3?393?+ ?+33�222333939310!367!#"'532677 !   !  326&#" N�
 �G�'A�NM7AQy"����������LECK� ��������^��Rpg[u����cd7�����{xxv����������  \�	)s  " 0 k@7		2## 2**1- GY-&GY&GY  ?2?+ 3?393?+ ?+33�222333939310!367!#"'53267732654&#" !"&5 !2�M��H�'A�MO9@Qy"�;m{zkl{zl����������^��Kwg[u����cd7)�����������̍�0���   w��91  ( P@*#'
!!  *

)#''LY@LY ?3�+ 3?�3+ 3333393910 #"'$  %6632 6632$%#"'9����#qv����.$D=5H1�}��E0-E��'ff)�������(ss$FC{&<2,B&������%**J��MKKM   \���  + T@,	$$**!!  -,'$**FY@	FY	 ?3�+ 33?�3+ 33333393910#"&'&54763266326654&'#"&'��	H69G	����nj�����99+>SOPI>=6D�1���&5:;6'%��#!RR"�����>'+!3�~��/816A  w��=� 1 G Y �@PLO=<TO@3HHOO
))#//

[#ZHOOLWLKKWW=G449==99B   MY,)&@&LY ?3+ �39?3+ 333/33/9/33/9/39333339333933��2910"'663   !"&'#   !2&&#"32673254&#"'&&#"#546632356654.54632�'ZDX<�P)����k�TM�t����)Q�<XD[&����`�JK�_���q��g2.+�?ni:pw�N����4@%,%NGNT�!-�/>�������cGRKN�xRw>/�-!�����pcen���A�6)3;1bt6&-&��]�V:5:Z   \���R ) @ R �@RDH54MH+AAHH#	(##TS@,AHHEPEDDP,P,P15511;@		FY ( @ FY&  ?2+ �39?3+ 333�23/99//9/393333339333933��2910  32&&#"3273265#"'632 !"'#"'&&#"#54>32356654.54632f�������|V?B%�wl����mv�'A>V|��������|z&��g2.+�":fT:pw�N���2B%,%NGNT)&<���������V�<��������pp��6)4;2Ee>$&-&��^�V;4:Y   w��=B 2 @ �@H?<;4788;;++((00

B#A4??@95=<8<<@@))   MY-&&LY ?3+ 39?3+ 3339/�23�2293333393933�2�2310"'663   !"&'#   !2&&#"327!3254&#'##'##'5�'ZDX<�P)����k�TM�t����)Q�<XD[&����PX6Y[����R72�181�27P�!-�/>�������cGRKN�xRw>/�-!�����J���T	���oY�gggg�Y     ��  * �@A	
)&%!""%% 		


,+))&#''"&&*
  ?223?33�23333933333939339993393�2�2 9910!!366!36!!#'##'##'5��f@�%��?�	j`4���ㅘ'R71�171�17P^��ov6�u��>?;��/��������X�ffff�X   w�#�  3@		LY LY  ?+ ?+ ?3339310  4$32&&#"!267!Z�����M���e[�Z���:�N���j�W�g�':�����  \��s  3@GY GY  ?+ ?+ ?3339310&  !2&#"327!Z���!��X�h~r�w}���* P�B����%�   h��y
  � ?/9910%'%7%7%LG�㴁���F���G��J����{���J;�{�Z�}�9I�Ĥ{�   �{��   @	   /�3�93�210#"&543!632#�6083m�
bm69�+3G8u^s9H   ��  @
 /�29/39�2102>32#&&#"##5N�wp:in?�+.IJ���%-&6ua1;47� ��X  $@  /�39393�9102&&546oGN%-%D1~�UX:5 :V�`MY  ��X  $@   /3�9393�91056654.54632�0E%-%NGNT�^�V; 5:Y   )����   ( 6 D R _ m �@JP4,H,,ck:&B&&^k^VkVnod^WjgS``gIA;O7EE>LLZ-%3))"00ZZgg
  /3�2/3�29/39/333�2229/333�22233�22299�93�293�2�93�2102#&&#"#62#&&#"#662#&&#"#66!2#&&#"#662#&&#"#66!2#&&#"#662#&&#"#6!2#&&#"#66�]qO<EN2K�\sO<EN2Kd�\sP<DN2Le��\sP<DN2Le�\sP<DN2Le��\sP<DN2Le�\sP<DN3K��\sP<DN2Le�e],,)/���f\,,)/Yif]-+'1Zif]-+'1Zi�f]-+'1Zif]-+'1Zi�hZ,,(0�f\-+'1Zh   )�}�     ' . 5 > b@3/2), !$6::$,2?@ #037;(++;3# /3/393333339993333333210#6736673#&'5&&'5'766'677'&&&'7BF$a5��Ia4��G�A݁�ZB�O݁�E�xbC��E�xb��C{LbR�C�&b'Z1B�O݁�G�A܂�!Ia5��F$a5��DnXb'X��DnXbY�F�cb��xF2�4bE�   ��V+�  ! " [@-!#
		"LY '!  ?2�2�2??993+/33�293339993�210!3!!!!4#!#"&'!3267�
�sN�������Z��w����Ysce{��>��V�T�L����������gS[_�o   ��oN?    ! _@/ "
		! @FY	# ??+ ??399�2�2/33�293339993�210!!!!47!#"&&'!3267�o+��މ������)���g
	Yqgd^�FF��������w���^ὩJ��lN_[��  /  ��   N@( LYLY LY ?+ ?99//3+ 3+33333333910!!3 !!#535!32654&##�+��z8���V��6h����O�����7!���HefeY    �   P@) JYJY  JY  ??+ 9/39/++ 33333333391035!!!3 !!#4&##32�1y�������mhg���5����?����o��A:��   �  ��   u@;
 

 	 LY	LY		 ??9/�2++ 99399399333393293999910'##!! 37'7654&##�_]X�sVr����
�D�:�R)w���>}p������5Rou5Zmh  ���s  ( �@A!"$"##&&*
)!$##" &"&GY
  GY  ?�2+ ???99+ 9939939933992393393999910"'#!336632'"337'7654&�p���+6�c���^�l4�qhktf�Re���;J�SS�����Ѡ{v����!��{dNl��   /  P�  A@   


LYLY ??+ 9/3+ 3333333910!!!!#53P����o�ʉ��������T�d    �^  A@   


FYGY ??+ 9/3+ 3333333910!!!!#53�� L���ω�^����^���   �� y�  U@+	 	 LY LYLY ??+ 9/+ ?+ 393333393910"!!!632#"&'32654&m5J�����k��1����n�J����������o������ס/Ͱ��   ��
�^  Y@-    
HYGY

HY ?+ 3??+ 9/+ 93333339910%#"'3265!"!!!632�z���r-y1t}��*.��1� JK���D����3��1��^�����    �V�   n@6
		 
LY		  ' ?33??39333333+ 3/333333333933333910!!!!!#!!!�?�!�@�R=�ը����������<��<��B��L�����   �oX^   i@4 
		 FY
# ??+ ?3?33933333/333333393333333910!!!!#!!!��;�d
���V���V����d;�?���������7��7��F�� �� ^���&�   �  �� N�#s&�   1    ��V��   J@$ 	 LY' ??33+ ?3933/333333233910!!#!!!�G�ո����6J��1
�L�����<��B�   ��o5^   M@&

 	 FY# ??+ 3??3933/333333233910!3!#!!}P�E)����7��1#^�������7��^����   �  P�  a@/    	 ?3?9333323339333333 9999910!!773!!#j|��6z�X���� �dZ����c�b�G�y����   �  �^  U@)

			  ?2?39333333�2233333 999910!737!!#'!�c��<�E���בa��^��{<������
�dy��    %�  `@/
 LY  
 ?33?9/3+ 3393933333333322931035!3#7!!!#�6��z�X�������ʉ/�������y��h^��1     �  h@3			 JY    ??9/3+ 3?39393333333933339931035!!!37!!!#�1;���9X�D�������Ϝs�������T����i���     ��   Q@'	

 		

   LY  ?+ 3?3939333333�2339910!7!!!!{{�X�������������c���y��h^����L     �^   F@" 		

 
 FY  ?+ ??3933�23333333310!!!!!��;�F����7�����^������7��y��   ��V��   F@#		   LY	
 LY	' ??3+ ?39/+/3333333310!!!!!!!!f+��������6C5�
�L�w�����=�J  ��o�^   G@$

FY

FY
# ??+ ??39/+/3333333310!!!!!!!��1�����V���^�R��������3^��  �  ��   B@! 

LY

LY ?3??+ 9/+/333333310!!!!!!!���������6C{���Lw�����=�J  �  ^   A@ 
FYFY ?+ ?39/+ ?/333333310!!!!!!��������V���^�R������3^��   �� ��   ]@/ "!LYLY
LY
 ?+ 3?3?+ 9/+ 933333933910632#"&'32654&#"!!!!s��"����m�P������:b�����\#������ס/ը������L�   ��
�^  ]@/@    
HYFY

HY ?+ 3?3?+ 9/+ 9333339�3310%#"'32654&##!!!!72�y���r-y1s���������P��D�� �3������y��^����   w���� ) 4 z@? 22/*/$$**  65$/ */*,2',MY'LY22!LY
MY
 ?�++ 3399?+ ?+ 993333333993933310327#"'#   !2&# 327&&546324#"66�bq.BLD>t��h�����E>8�.N\N��ȱ?Mǿ����p7>8&=J���p�b"�W}�����L�}�����{jz�18�   \���s * 3 �@H"220+0%%+++  54 +%0+0.2(.FY((GY22 ""  GY
JY
 ?�+ 3+ 3/399?+ 9/+ 9933333339393933310327#"'#"  32&#"327&&546324&#"6�VN*;@HT�b�����*y0CX8ohol*�����,-ZLg�v�4�V"74�����O�M����9H�~W@ �� w���& &   9  �� \��s& F   �    )�Vy�  6@
  LY LY' ??+ ?+ 393333310!!!!!!�+�����sP�s
�L����  /�o=^  :@



FYFY# ??+ ?+ 333933310!!!!!5=��������^��f���y���    �� <     ��^  5@  ??33?33333933310!!367!����NP�$"�N�M��^�I�<�`���      ��  ^@.	   LY 		 ??39/3939+ 33333933339910!!!!!!5!1N�?������?�P\Z��)�����    ��^  L@%
	
			FY ??33+ 3?33339939333310!!!!5!!367!������#�NP�$"�N�M����^�I�<�`���   �V��   ^@. 	


		
 LY' ??3+ 3?39333/33332993239333910!!#!!!�%�ժ��������:V;5N�5�
�L�)�������+�  
�o^    g@3 
		  FY
# ?3??+ 39333?/33333399339399910!!!!#!!3���Z��Z����������
;#��d���������  )�VH�  K@% @ ' LY	 LY  ?+ ?3+ 39/?333993�310!!!!!!!!���;�i6+������N��T�L�   /�o7^  D@"
		FYFY
# ??+ 3?3+ 3333993�310!!!!!!#5����1����^��ly�����y�   m�VF�   @@    	LY		 LY' ??+ ?39/+/333333310!!!#"&5!3267!+���ʚ�]��5buR�w6�
�L�54&ɶ\��jk!)��J  {�o�^   @@ 			FY	FY# ??+ ?39/+/3333333103267!!!!#"&5��X�M1����j�U���^�g�( �������8.�����  m  �  J@$LY  ?3?9/333+ 3933333933310#"&5!367!!#q((��5bm�Y�6�ʁn��ɶ\��neH��3��J5-��  {  �^  J@$FY  ?3?9/333+ 3933333933310#"&5!33367!!#F3��1�}N^1��iC}Z����g� �)����6�  �  f�  +@
		LY
  ??39/+3333310!6632!4&#"!�6��[����buO�v�����3'Ǹ��jk *�q  �  �^  -@ 
FY  ?3?9/+3333310!4#"!!6632������1j�W����H�^�D8.���`    ���� ! ( c@3%

&*) $ ""LY%@LY	  LY ?+ 3?9/3+ �3+ 99333333933310%2$7#  #"&547333 !  !"!4&b�Ln}������?��5�`)%d%\[��ҕ����]D��KBU6�ztYHX8�u�|G��ݳ���   ��`s  % g@5" #'&$!	!FY JY"@  JY ?+ ?9/�3+ 3+ 99393333339333106$32 !3267#  ' 54733%"!&&N!�����j�bN��������)�`%^|	�w������+-�'(��`E75N�syp|   �V�� $ + }@@#$$))!(-
,$''%%LY(	@LY "MY " ?3+ 3?9/3+ �3+ 99?3333933339939310& #"&547333 !  !32$7!"!4&����?��5�`)%d%\[��Ҽ�Lnm�~�����(I�ztYHX8�u�|G��]D��@>	�du����   �o`s   ' �@C  %%$
)

( #&##!FYJY$@ !JY ?+ ?9/�3+ 3+ 9939?3333933339939310&&' 5473336$32 !3267!"!&&ݵ���)�`!�����j�b���^|	�w(���`E75N�����+-�?�+syp|�� B  �� ,  ��    ��&�  6uR �& +5��    �?&�  6/   �& +5  �� ��  X@,	

! LY  MY	 ??39/3+ 3?+ 33333393399310"!!7!32#"&'32654&�Ko��6��X���/����n�J������ ��@���P������ס/Ͱ��  ��
�^  X@,   GY

HY ?+ 3??39/3+ 33333339939310%#"'32654&#"!!!2 �y���r-y1t~��2z��1�X�'�D�� �3������^�����  �V��   I@%

 'LYLYLY ?+ ?+ ?+ ?/333�2939310!!!'"'5326!!!=����>_��T@:35>7[ �N���u����c��aW�T�L�   �o�^   N@(   FYHY FY# ??+ ?+ 3?+/33�29339310%!!!!#"'5326!�+��݉���� \�|jD119M=N�����y����� ��O��  �� f�  C@"  LY

LY ?+ 3??39/+333333910%#"'3265!!!!!f�����K�R~�����6C5Z���/��������=   ��
�^  E@"		HY FY ??39/+ ?+ 3333�33310!!!! #"&'3267���1�1���Lv@prlo��3^�R������ :���   ��V��   L@&		   LY	
 LY	' ??3+ ?39/+/33�293333310!!!!!!!!fN����������6C5�
�L�w�����=�J  ��o�^   M@'

	FY

FY
# ??+ ??39/+/33�293333310!!!!!!!��1+��݉���V���^�R��������3^��  m�V�  =@  	LY		'LY ?+ ??39/+333333310!!!3#"&5!3267!�������]��5buR�w6�V�+4&ɶ\��jk!)�  {�o�^  =@		FY
#
FY
 ?+ ??39/+3333333103267!!!35#"&5��X�M1�����j�U��^�g�( ����op�8.���  ��V!�   T@* 		'	LY  ?33+ ?3993?/33�2933393310!#!!3!!!!46#!#��	���Zo�N������	��L{��u�X���^�T�L��1���   ��oL^   U@+
    FY# ??+ ?3?3993/33�2933393310%!!!#&''!!>!!+��މ��6+���+1����3	!%,�������q>�l��n�D��^�#M�G��n��� �� B  �� ,  ��    ��& $  6 uR �& +5�� V��\?& D  6)  �&& +5��    �V& $   j VR 
�#& +55�� V��;& D   j�  
�8& +55��    %� �  �� V���u �  �� v  A�& (  6 R �& +5�� \��b?& H  6  �& +5  ����   =@

LYLY LY ?+ ?+ 9/+33333310"6$3   !  5!&&267!3���p��Z���������+ӕ�����[GSE�n�����u��H���#����   \��ws   =@

JY JYFY ?+ ?+ 9/+33333310%267!   !" 55!&&#"566Zcv
�>t<6��� ������c�kX��vun}���������𔂒&2�,$�� ���V&�   j �R 
�1& +55�� \��w&�   j�  
�1& +55��    �V&�   jXR 
�'& +55��    �&�   j   
�'& +55�� ^���V&�   j -R 
�<& +55�� N��#&�   j�  
�>& +55  9��j�  P@(		  MYMYLY ?+ 9?+ 9/+ 33339939310!!! '32654&##h����P� �������]�h����{Z\ ��d
����O,5irf_   9�V^  R@)		 FYGYFY ?+ 9?+ 9/+ 33333939310!5!#"'32654&##�����F��������\�e����v����b����xP-3����� �  ��&�  M �R �& +5�� �  #�&�  Mu  �& +5�� �  �V&�   j �R 
�%& +55�� �  #&�   ju  
�#& +55�� w���V& 2   j �R 
�+& +55�� \���& R   j  
�/& +55  w����    ?@   LY		LY	LY ?+ ?+ 9/+33339910 !   !  267!"!&&���������iQQe�H�������������z�mm��|������ۮ���  \���s    ?@   JY

GY
GY ?+ ?+ 9/+33333310 !"&5 !2267!"!&&�������������ap�>ndbp�m1���̍�0���� tttt�qppq �� w���V&~   j �R 
�/& +55�� \���&   j  
�1& +55�� H���V&�   j #R 
�/& +55�� J���&�   j�  
�/& +55��  ��9�&�  M 1R �& +5��  ���& \  M�  �& +5��  ��9V&�   j 1R 
�)& +55��  ��& \   j�  
�,& +55��  ��9s&�  S �R 
�&& +55��  ��!& \  SR  
�)& +55�� m  V&�   j VR 
�)& +55�� {  �&�   j#  
�(& +55  ��VT� 	 /@
	LY	LY' ??+ ?+3333310!!!!T��+������ �T�L��   ��o�^ 	 /@
	FY	FY# ??+ ?+3333310!!!!��-����^��f���^�� �  �V&�   j5R 
�-& +55�� �  -&�   j �   
�,& +55�� /�P�&�  � �   � >+5�� ��^&�  � �   � >+5��  ��� & ;  ��   ���� >+5 �� 
�^ & [  ��   �����>+5      V�  a@1
	
 LY   ?3?9/3+ 3399333393393333310!!!!!!!!q)��V;5N��'��������������hN�������)��j   
  �^  i@5
	
 FY   ?3?9/3+ 33993333933939393103!!3#!!#f���Z��Z����.������+�����d�J��=���   \  b� 	  4@  LYLY ??+ 9/+33333104$!3!! #"33\8{5�V���P����h���1�J�Yefe �� \��q G    \����  & S@)&& (   '
##LYLY ??9/+ 39/+ 3933339339104$!3!3265!#"&'#"&#"3265\*s5OVZN1��l�'+�}���H��][Tb���1��BAfq��-��N=?J��il`fA;   \���   , W@-	$.*- 	 (GYHY  !GY  ?+ 3+ ?+ 999/?333393910" 323&&5!32655!#"&''26754&#"^������j
1PXWK-��x�>.�Zofjq�b(6�&�*f�iKFfq�����=L7R�!������   ���� ( R@)  $*$)MY&&!MY&
LY ?+ ?+ 9/3/+ 9333933339103265!#"&54&##53 54&#"'6!2�����SUYO1����ù��Xkq�����o��$��eYfq��-����jm��NXdΐ�   9��\s ( V@+'"
*
)('('JY	((  HY FY ?+ ?+ 99//9+ 9333933339102654&#"'663232655!#"&54&##5���erM�OZxׄ�����WK-��������8=66%"�.&���9
'�zfq����̙�ef�   �Vs�  [@.  

! MYMYLY' ??+ ?+ 9/+ 99333333933910!!!4&##53 54#"'6!2����+�����ȶ�u��*�o��$����L��jm�Ѧdΐ�  N�o-s " ]@/"
$
#!""!JY	""FY#FY ?+ ??+ 9/9+ 99333333939102654&#"'6632!!!4&##5���jzM�PZw����сo���י���8=66&!�-'���9
"}eg���FNI�  ���� ! D@!   		#"  LY LY ?3+ 3?+ 9/3339933103265!#"&5!'"'5326!OWZN2������>_��T@:35>7[ rwHCfq��-����=���c��aW   ���^  D@! 		! FYHY ?3+ 3?+ 9/33399331032655!#"&5##"'5326!jPXWK-����� \�|jD119M=/yJCfq������� ����� ��O   �����  Z@- 			  LYLY ?+ ??99//+ 3933333333933103265!#"&'!!!!!=IUUI1��������65}KFfq��-���������=   ���^  Z@-FYHY ?+ ??99//+ 393333333393310!!32655!#"&'5!!��2NQUI-�����k��^�R��HCfq�������V�3^  w����  @@!LY LY  LY ?+ ?9/++ 333393910! !  4$3 &&#"32655!5����������M��kr�h���Ӛ���5{�����g�T�k�9*�������  \���s  @@!
GY FY  
GY ?+ ?9/++ 333393910!!   !2&&#"!265!�\������E,��\K�H�������]��*0V�#'����tc   )��b�  ?@ 	 		LYLY ?+ ?9/+ 3333939103265!#"&5!!!�KVXL1�����sP�s}KFfq��-��˾?��   /��F^  ?@		FY

HY ?+ ?9/+ 333393910!32655!#"&'!5=��PXVL-������^��KFfq��������   X���� ( R@)%  "*"")%MYLY
LY ?+ ?+ 9/+ 93333933991046632&#"33#"32$7! $54675&&�����v��΅���z��릪�	a�������̷��`i�[CO�wQKfX�haga1/��O�ʒ��  N��%s $ N@'!!&%$$JY$$FYFY ?+ ?+ 9/+ 93339993310#"!267! $54675&54$32&#"3H��� o�X������瀐��o�[R��ㅏ��DIy.(�M��k�
1э�,(�GhB7�� �b� &�  �9   �   >+5��  ��^ &�  ��   �   >+5��  �R��& $   gD  �� V�R;u& D   g�  ��    ��& $  f#R �& +5�� V��;�& D  f�   �'& +5��    ��& $  w!R 
�& +55�� V���& D  w�   
�)& +55��    ��& $  xR 
�& +55������;& D  x�   
�0& +55��    �J& $  y!R 
�'& +55�� V����& D  y�   
�<& +55��    �b& $  zR 
�,& +55�� V��;& D  z�   
�A& +55��  �R�s& $   'K XRgD   
�& +5�� V�R; & D   &K��g�   
�##& +5��    �& $  {)R 
�& +55�� V��;�& D  {�   
�.& +55��    �& $  |'R 
� & +55�� V��;�& D  |�   
�5& +55��    �X& $  }'R 
�+& +55�� V��;& D  }�   
�@& +55��    �b& $  ~'R 
�& +55�� V��;& D  ~�   
�,& +55   �R�}    $  !!!!&'#"&'3327432#"7j��j��{���%!�Fܦ���/UU����TR�\����D`�|$������/6}�j��GN�� V�R;+& D   'g�  N�  �/& +5�� ��R�& (   g�  �� \�Rbs& H   g�  �� �  �& (  f�R �& +5�� \��b�& H  f�   � & +5�� �  `& (  R��R �& +5�� \��b& H  R�  � & +5�� �  ��& (  w�R 
�& +55�� \��& H  w�   
�"& +55����  �& (  x�R 
�& +55������b& H  x�   
�)& +55�� �  �J& (  y�R 
�%& +55�� \����& H  y�   
�5& +55�� �  b& (  z�R 
�*& +55�� \��b& H  z�   
�:& +55�� ��Rs& (   'K��Rg�   �& +5�� \�Tb!& H   &K� g�  �)& +5�� B  ��& ,  f�R �& +5�� u  <�& �  f�   �& +5�� B�R��& ,   g  �� ��R�& L   g�  �� w�R��& 2   g�  �� \�R�s& R   g�  �� w����& 2  f�R �& +5�� \����& R  f�   �& +5�� w����& 2  w�R 
�& +55�� \��
& R  w�   
� & +55�� w����& 2  x�R 
�#& +55�������& R  x�   
�'& +55�� w���J& 2  y�R 
�/& +55�� \����& R  y�   
�3& +55�� w���b& 2  z�R 
�4& +55�� \���& R  z�   
�8& +55�� w�R�s& 2   'g�  K �R �& +5�� \�R�!& R   'g�  K  �#& +5�� w���s&_   vR �& +5�� \���!&`   v}  �$& +5�� w���s&_   C dR �'& +5�� \���!&`   C�  �,& +5�� w����&_  f�R �"& +5�� \����&`  f�   �'& +5�� w���`&_  R �R �"& +5�� \���&`  R  �'& +5�� w�R�&_   g�  �� \�R�&`   g�  �� ��R^�& 8   g�  �� ��R�^& X   g  �� ���^�& 8  f^R �& +5�� �����& X  f�   �& +5�� ���)s&a   vR �&& +5�� ���s!&b   v �   � & +5�� ���)s&a   C R �&& +5�� ���s!&b   C�  � & +5�� ���)�&a  fdR �!& +5�� ���s�&b  f�   �$& +5�� ���)`&a  R �R �!& +5�� ���s&b  R3  �#& +5�� ��R)&a   g}  �� ��Rs&b   g  ��  �R��& <   g�  ��  ��^& \   gV  ��    ��& <  f�R �& +5��  ���& \  f�   �& +5��    �`& <  R R �& +5��  ��& \  R�  �& +5�� \��& �    B �   ����! 	  �
  /2�]210&&'5!!&&'5!�F>�"-!d)��I�-!d)�1�7H�89�2H�8 �-� 9   @


 /3�]29/�10#&'#567!'673#�pcra�pg;5�YU5�C���K[eA��N��[nYu ���   @
 /�]239/�1067!#&'#7#&'53�/pg<1~(�arji�X��@�6S�H�,Ae`F�wWpY  �-����    %@ /3�]29/�239310#'6654&#"5632#&'#567!!}
7B%+#%F^qȢpcra�pg;5�`r=t
H�)K[eA��N� �1��  % )@  		!!!! /3�]2�2/39/3/310".#"#663232673#&'#567!�7$KHC(+q	kS%MHB))qj���ZS���B0�<!1o�$0t}��GQJN�`E�; �1���   @ /�]2�3910673#%#"&'33267�7F/�\s��à���sXXr	�i`naN����WS^L �1���   @
 /3�]2�910#&'53%32673#"&'� �je�/F��rY[p�	�����Uz`i3K_WS���� �1��    -@   /33/�]2393�]210#'6654#"563232673#"&'�126k
3';5FVd��rY[p�	����4A)n	)hC�K_WS����  �1��  $ +@"@	H"	 /3�]2�2/3�+2/3103273#"&'%".#"#663232673��jb��	����$KHC+(q	b\%MHB))qh;F�����1$.dy$0mp   
��    +@     /?39393393104&'3#"'5326�NF�OB#�pJR<7#-�4mB<KP/g�(  �)/  @
	  ?2/93310"'5325!�dU;<{'�����T��   �)  @

  ?2/93310"'5325!�dU;<{'����V�}��   -  �  *@
  		
 ??3939339910!!77'3��-$����N��+!��w  f��y�   (@ 	OY&OY ?+ ?+33331032654&#" #"  32 �etrefsre���������;������������26��  =  7s  *@
  		
 ??3939339910!!77'!7��SÖ�
��D��w  B  ?�  A@   

NY&NY ?+ 9?+ 9333399310!!5>54&#"'6632!?�p�Z,PTT�X�����z�� �mTP03@MH�wZ��x�{   N��B� & V@-  "(""'PY|
$$OY$&
OY
% ?+ ?+ 9/_^]+ 93333933910!"'32654&##532654#"'6!2���������U�d����oq���H�[���+��$����O+6hsgV�Yl�0;Ր�  ��ys 
  F@"	  PY	% ??39/3+ 3933393339910%#!!5!3!5467#y��������#V���s�����2�"0�%��   d��5r  P@( OY  NYOY% ?+ ?+ 9/+ 33333933993102 !"'3 54!"'!!76f��������O�^��5�({7��#=b�����O*5��B������� H��P�     7��Pp  ,@  NY $ ??+ 93339310!!�%�/������� �� H��J�     B��J�  % F@###  &'  PYOY&PY% ?+ ?+ 9/+ 999399210 !"'532667##"&54 32%"32654&J�����CT\��j:�r������`lbd^�}�P�V�[ë^L��������|j|{Pw��� )  � & I    I    R��� # 4 �@@4$,+,-0&(() )200//)562&&,*$$) 0))*5-* ?33/339/33/3399333/993939�223399333310#"'532654&'.54632&&#"##33#7#�uoXsX-/#%lH'�r_p48<'%-*JiF���������dq+�6'#&5<N4]r4}!",$3]��o�^����/�y�� �� )�y�& 7    z�  �� /�7L& W    zB    \�qs  & I@&#	('%#!!GY! GYFY ?3+ ?+ ?+ 99?9333310%26754&#"!"'532557##"3237!oxgo{�ks���������k������vۋ�%���������B�V���63���� \�q!&�  K  �4& +5�� \�q+&�  N
  �*& +5�� \�q&�  OP   �.& +5�� \�q!&�  : �   �+& +5  �  ��  �   ??9103!�6��J����  s&�   C�zR �& +5�� �  �s&�   v�[R �& +5����  s&�  K��R �& +5����  �V&�   j��R 
�& +55����  �`&�  R��R �& +5��   ��&�  M��R �& +5����  �}&�  N��R �& +5�� n��&�   Qd �� �  �f&�  O R �& +5�� ��R� &�    -  ����  �� '� �  T���� �  ?5 �� �  ���  ����  �V&�   j��R 
�& +55�� �  ���  ����  �V&�   j��R 
�& +55�� �  ���  �� �  ���  �� �  R�&�  f�R �& +5�� ��R��&�   g�     � �  X    / \        $ $ $ $ V z �z�p��� Kh}���+y�*��
}�Hq����	R	�	�

5
�
�
�Zy��<{�$���m��:Xz���:��s�Q���?V��0��e��q�:���++\�`��`�f���m���.���#D~��5K`v��� 	  , = � � � � � � �!! !2!�!�!�!�!�!�!�""v"�"�"�"�"�##�#�#�#�#�#�#�$�$�$�$�$�$�$�$�%%%�%�%�%�%�%�%�&4&�&�&�&�&�&�'>'O'`'p'�'�'�'�'�'�'�'�'�(((.(?(K(S(�(�(�(�)))$)0)<)M)])n)~)�)�)�)�)�)�)�**R*�*�*�*�*�*�+++#+4+K+W+c+t+�+�+�+�+�,,,,-,9,E,Q,�,�,�,�,�-	--*-6-�-�-�-�...*.;.�/2/C/S/_/k/|/�/�/�/�/�/�/�/�0000.0?0~0�0�0�111,1<1N1_1q1�1�1�1�1�1�1�1�222"232D2T2~2�3X3�444/4?4J4U4�4�4�4�55M5u5�5�66Z6n6w6�6�6�6�6�6�777767>7F7N7V7�7�7�7�7�88D8L8q8y8�8�8�9A9I9�9�::!:1:A:Q:b:t:�;E;�<<o<�==`=�=�=�>>7>�>�>�?H?�?�@@W@�A$AvA�A�A�BBB)B;B�B�B�B�CCC!C�C�D&D7DHDzD�D�D�D�E(E0E�E�FF,FaF�F�F�F�F�F�F�F�G!G)G1GdG�G�HH]H�H�I;I�I�I�JZJ�J�K"K*K}K�LL$L[L�L�MMMDMLMTM{M�M�M�N%N]N�N�OObO�O�PCP�P�QQQmQuQ}Q�Q�Q�RIR�R�R�R�SS>SOS`SqS�S�S�S�S�S�S�TT+TLTkT�T�T�UUAU�U�VV^V�WW	W7WfWrW�W�XX�X�Y�Y�ZWZ�[([0[�[�[�[�[�\>\w\�\�\�]$]�]�]�^(^`^�^�^�^�__?_a_�_�_�``p`�`�aLa�a�a�a�a�a�a�a�a�a�a�a�a�a�b�c\cmcuddKd�d�d�d�d�ee:ee�e�e�f`f�gggg"gNgdgug�g�g�h)h�h�i(i�i�j6j�j�k\k�lOl�m�n0n�n�n�oSo�o�p<pNp`p�qqq�rUs+s�t�u0utu�u�vvJv{v�w�x=x�yyly�z*z�z�{!{~{�|D|�|�|�}}Y}�~~Y~�J�׀�Y������@�L�X���Â˃�Z����]����/�z�ˆ�R�����o���v�~������a����S����4�z�������������ˌӌی���P�����č֍����a���Ȏ؎�����s�ɏۏ���� �0�B�S�e�v�����Ȑ����-�@�U�j�Œ �]�e�˓;����d�Ǖ!�v�ϖ'�z�ȗ�Q����(�;�G�S�d�u���������Ϙ����0�B�T�f�x�����������"�.�?�P�a�q���������˚ݚ���*�;�L�X�d�p�|�������ԛ���
��.�C�W�h�x���������̜ܜ��� ���.�?�P�a�q�����������̝؝�����'�3�`���Ɵ�]��� �\�����ڡ�H�w�â(�r�ʢҢ���c�o� ���x���������Ϥ����%�6�G�R�c�o�������������ť֥�      ۷�b�_<� 	     �B�    �+�����
��  	       � �        J u� �+ -� X5 ?  R! �� R� =\ ?� XR ?� =H uN � J� y� N� N� #� d� H� 7� H� BH uR ?� X� X� X� - f�  ` � w� �{ �d �� w � B��hP �� �� �� �^ w �^ wH �h ^� ) �3  �  V  �  � 1� �N � 3B J���L� V � \ \� \ )� B �q �q�}� �q �� �B �� \ � \� �� \y /B ��  � � 
�  � 7' h�' R� X  J u� �� R� q� h�� j�� d /� R� X� =� d ��m \� X / ;�LH �= qH u��� \ 9� R . . Z� =�  �  �  �  �  �  �   w{ �{ �{ �{ � * B�� 9� /� �^ w^ w^ w^ w^ w� �^ w � � � ��   �� �� V� V� V� V� V� VV V \� \� \� \� \q��q �q��q��� \B �� \� \� \� \� \� X� \B �B �B �B ��   ��  �  � V�  � V�  � V w \ w \ w \ w \� � \� /1 \{ �� \{ �� \{ �� \{ �� \{ �� \� w� � w� � w� � w�  �B �  B ��q�� ?q�� q�� Bq + Bq �� B� ���hq�}P �� �� �� �q �� �q c� �q �� �m �� �  � �B �� �B �� �B �; � �B �^ w� \^ w� \^ w� \� w� \H �� �H �� cH �� Sh ^� \h ^� \h ^� \h ^� \� )y /� )y /� )y / �B � �B � �B � �B � �B � �B ��  � �  �  �  � 1� 7� 1� 7� 1� 7 �� ��  � V�  V V^ w� \h ^� \� �� ��� �q ��T� 
� �� ���� ����H u
������������J��B���  ` �} �D 9{ �� 1 �^ w BP �3  � �� �� R^ w� � �� N� )�  � \V   mJ 7 9�  - \q NB �B �) �- \H �� � \q N� \B �� \B �� �� H �� � \� \� � y� \9 \N )) �V \���� �� mB ) �� \) �� m{ �q )} �j wh ^ B 9��h�  �q )` �9  � ��   �` �} � 
{ ��  / ^� �� �` �� � � �^ w� � � w� )9  � \V  ? �� m� �� ��  ? � �N H� �R��� V� \ �� �P � \�  q N� �� �� �)  � �L �� \7 � � \m /�  � \� 
� �? {� �� ��  � �� � J ��  � \B � �1 \� \q �q��q�}   �B � ��  ` �� � ��  � �  � �  � �  �    R  R  RJ��� � T ?� � � % ?! {5 { b� u
? ?! �� �� R� R� u
�wb f� #� R# �� B\ ?) )9 �� J 7� f : ; Z C� ;D 9� � )� Xd %� qL  � X� X� V� X� X� )� )� hq�} ^ ^ N )  T - ; - +            �     V  y  H  �   �            T  Tq�}� � )  � 3� �� ��  � V��r� X  y� )� )� wo \ � �  �  ��  ��  ��  ��{ �� �� \� �� w b  L  � �f ��    
 �7 �o )� � �
 � )q  m� �^ w� \�  �  �  �  
� w	) \� wo \� w \� w j w1 \� hu �� ������ )� )T �j �� /�  � �y /� � �� �;  �  / ^q N �R �P �� �% � �  �  � �� �� � �	  � �7 w? \ w \� )f /�  �  �  �  �   
q )T /o m� {� m? {� �T ��  �  �  �   B�  �   �J �� �   �L �� �� �� m? {J �h � B�  � V�  � V�  V V{ v� \� �� \� �� \�  �  / ^q N� 9� 9� �� �� �� �^ w� \^ w� \^ w� \N H J9  �  9  �  9  �  � m? {} �� �? �� �y /� �  ) 
V  � 
 \ \h \b \N � 9� J ND {  X �� �f wN \ )� // Xs N� �  �  � V�  � V�  � V�  ����  � V�  � V�  � V�  � V�  � V�  � V�  � V�  � V{ �� \{ �� \{ �� \{ �� \{�����{ �� \{ �� \{ �� \ Bq u Bq �^ w� \^ w� \^ w� \^ w���^ w� \^ w� \^ w� \� wo \� wo \� wo \� wo \� wo \ �B � �B � � � � � � � � � � ��  �  �  �  �  �  1 \  �  �-  �  �-  �1  �1  �1  �1  �1� 
V V � -� f� =� B� N� � d� H� 7� H� B1 )� R� )y / \ \ \ \ \� ����� ����������� ���� n� �� ���� ��� ��� � � � �     ���  
���y
�               � �   �3  �3  � f�� �@  [   (    1ASC    ��� ��X  �    ^�              |   � �  F H I ~ � �'2ac�����7�����	#�����������OP\_�������?������M    " & 0 3 : < D p y  � � �!!!! !"!&!.!^"""""""+"H"`"e%��������     I J � � �(3bd�����7����� 	#����������� PQ]`������� >������M       & 0 2 9 < D p t  � � �!!!! !"!&!.!["""""""+"H"`"d%�� ��������M�������  ��-���� � � a�I    �������v�h�c�b�] g�D�� ���� 	�����������  �����  ���h�	���	���	�X��z�}  �}��{��B������������������������v�t  ���	�n���������%�"������������i  OS              �                 �                                             �       �                         �                                       v                                       R      � �� �� �� �� ��IJ$%h������������ik���F�u�45]^@G[ZYXUTSRQPONMLKJIHGFEDCBA@?>=<;:9876510/.-,('&%$#"!
	 , �`E�% Fa#E#aH-, EhD-,E#F`� a �F`�&#HH-,E#F#a� ` �&a� a�&#HH-,E#F`�@a �f`�&#HH-,E#F#a�@` �&a�@a�&#HH-, < <-, E# ��D# �ZQX# ��D#Y ��QX# �MD#Y �&QX# �D#Y!!-,  EhD �` E�Fvh�E`D-,�
C#Ce
-, �
C#C-, �(#p�(>�(#p�(E:� -, E�%Ead�PQXED!!Y-,I�#D-, E� C`D-,�C�Ce
-, i�@a� � �,���� b`+d#da\X�aY-,�E����+�)#D�)z�-,Ee�,#DE�+#D-,KRXED!!Y-,KQXED!!Y-,�%# �� �`#��-,�%# �� �a#��-,�%� ��-,�C�RX!!!!!F#F`��F# F�`�a���b# #���pE` � PX�a�����F�Y�`h:Y-, E�%FRK�Q[X�%F ha�%�%?#!8!Y-, E�%FPX�%F ha�%�%?#!8!Y-, �C�C-,!!d#d��@ b-,!��QXd#d��  b� @/+Y�`-,!��QXd#d��Ub� �/+Y�`-,d#d��@ b`#!-,KSX��%Id#Ei�@�a��b� aj�#D#��!#� 9/Y-,KSX �%Idi �&�%Id#a��b� aj�#D�&����#D���#D����& 9# 9//Y-,E#E`#E`#E`#vh��b -,�H+-, E� TX�@D E�@aD!!Y-,E�0/E#Ea`�`iD-,KQX�/#p�#B!!Y-,KQX �%EiSXD!!Y!!Y-,E�C� `c�`iD-,�/ED-,E# E�`D-,F#F`��F# F�`�a���b# #���pE` � PX�a�������Yh:-,K#QX� 3��4 �3 4 YDD-,�CX�&E�Xdf�`d� `f X!�@Y�aY#XeY�)#D#�)�!!!!!Y-,�CTXKS#KQZX8!!Y!!!!Y-,�CX�%Ed� `f X!�@Y�a#XeY�)#D�%�% XY�%�% F�%#B<�%�%�%�% F�%�`#B< X Y�%�%�)�) EeD�%�%�)�%�% XY�%�%CH�%�%�%�%�`CH!Y!!!!!!!-,�%  F�%#B�%�%EH!!!!-,�% �%�%CH!!!-,E# E � P X#e#Y#h �@PX!�@Y#XeY�`D-,KS#KQZX E�`D!!Y-,KTX E�`D!!Y-,KS#KQZX8!!Y-,� !KTX8!!Y-,�CTX�F+!!!!Y-,�CTX�G+!!!Y-,�CTX�H+!!!!Y-,�CTX�I+!!!Y-, �#KS�KQZX#8!!Y-, �%I� SX �@8!Y-,F#F`#Fa#  F�a���b��@@�pE`h:-, �#Id�#SX<!Y-,KRX}zY-,� KKTB-,� B�#�Q�@�SZX�   �TX�C`BY�$�QX�   @�TX�C`B�$�TX� C`B KKRX�C`BY�@  ��TX�C`BY�@  �c� �TX�C`BY�@  c� �TX�C`BY�&�QX�@  c� �TX�@C`BY�@  c� �TX��C`BYYYYYY� CTX@
@@	@�CTX�@�  	 ���CRX�@���	@�@�� 	@Y�@  ��U�@  c� �UZX� � YYYBBBBB-,Eh#KQX# E d�@PX|Yh�`YD-,� �%�%�#> �#>��
#eB�#B�#? �#?��#eB�#B�-,���CP��CT[X!#� ���Y-,�Y+-,��-@�	!H U UHU�PLOMdNLd&4U%3$U���MLdLLF3UU3U?�KF�F�F#3"U3U3UU3U��03 Uo  � �  ����TS++K��RK�	P[���%S���@QZ��� UZ[X��Y��� BK�2SX� YK�dSX�� BYss+ss+++++s^st++++t+++++++++++++^   �  u��              ^  {  ��    ��    ��  ���  � ������������ �V                                                            � � + � � � � � � �  T      �  	   r    	   r  	   �  	  . �  	   �  	   �  	   �  	  �  	  (�  	  8�  	  \  	  \h  	  T� D i g i t i z e d   d a t a   c o p y r i g h t   �   2 0 1 0 - 2 0 1 1 ,   G o o g l e   C o r p o r a t i o n . O p e n   S a n s B o l d 1 . 1 0 ; 1 A S C ; O p e n S a n s - B o l d O p e n   S a n s   B o l d V e r s i o n   1 . 1 0 O p e n S a n s - B o l d O p e n   S a n s   i s   a   t r a d e m a r k   o f   G o o g l e   a n d   m a y   b e   r e g i s t e r e d   i n   c e r t a i n   j u r i s d i c t i o n s . A s c e n d e r   C o r p o r a t i o n h t t p : / / w w w . a s c e n d e r c o r p . c o m / h t t p : / / w w w . a s c e n d e r c o r p . c o m / t y p e d e s i g n e r s . h t m l L i c e n s e d   u n d e r   t h e   A p a c h e   L i c e n s e ,   V e r s i o n   2 . 0 h t t p : / / w w w . a p a c h e . o r g / l i c e n s e s / L I C E N S E - 2 . 0         �f f                    �          	 
                        ! " # $ % & ' ( ) * + - . / 0 1 2 3 4 5 6 7 8 9 : ; < = > ? @ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z [ \ ] ^ _ ` a � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � b c � d � e � �	 � f � � � � g � � � � � h � � � j i k m l n � o q p r s u t v w � x z y { } | � �  ~ � � � � �
 � � �  !" � �#$%&'()*+,-./0123 �456789:;<=>?@AB � �CDEFGHIJKLMNOPQ � �RSTUVWXYZ[ � � � �\]^_`abcdefghijklmnopq �rstu � �v �wxyz{|}~ � � � � � � � � ��������������������������������������������������������� ������������������������������������������������������������������������� 	
 !"#$%&'()*+ � �,- � � �. � � � � � � � �/0 � �1 �2 �345678 � �9:;<= � � � � � � � � � � � � �>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~�������������������������������������������������������������������������������������������������������������������������������� 	
 !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~�������������������������������� , � � � ����� �����������nullI.altuni00AD	overscore
Igrave.alt
Iacute.altIcircumflex.altIdieresis.altAmacronamacronAbreveabreveAogonekaogonekCcircumflexccircumflexCdotcdotDcarondcaronDcroatEmacronemacronEbreveebreve
Edotaccent
edotaccentEogonekeogonekEcaronecaronGcircumflexgcircumflexGdotgdotGcommaaccentgcommaaccentHcircumflexhcircumflexHbarhbar
Itilde.altitildeImacron.altimacron
Ibreve.altibreveIogonek.altiogonekIdotaccent.altIJ.altijJcircumflexjcircumflexKcommaaccentkcommaaccentkgreenlandicLacutelacuteLcommaaccentlcommaaccentLcaronlcaronLdotldotNacutenacuteNcommaaccentncommaaccentNcaronncaronnapostropheEngengOmacronomacronObreveobreveOhungarumlautohungarumlautRacuteracuteRcommaaccentrcommaaccentRcaronrcaronSacutesacuteScircumflexscircumflexTcommaaccenttcommaaccentTcarontcaronTbartbarUtildeutildeUmacronumacronUbreveubreveUringuringUhungarumlautuhungarumlautUogonekuogonekWcircumflexwcircumflexYcircumflexycircumflexZacutezacute
Zdotaccent
zdotaccentlongs
Aringacute
aringacuteAEacuteaeacuteOslashacuteoslashacuteScommaaccentscommaaccenttonosdieresistonos
Alphatonos	anoteleiaEpsilontonosEtatonosIotatonos.altOmicrontonosUpsilontonos
OmegatonosiotadieresistonosAlphaBetaGammauni0394EpsilonZetaEtaThetaIota.altKappaLambdaMuNuXiOmicronPiRhoSigmaTauUpsilonPhiChiPsiuni03A9Iotadieresis.altUpsilondieresis
alphatonosepsilontonosetatonos	iotatonosupsilondieresistonosalphabetagammadeltaepsilonzetaetathetaiotakappalambdauni03BCnuxiomicronrhosigma1sigmatauupsilonphichipsiomegaiotadieresisupsilondieresisomicrontonosupsilontonos
omegatonos	afii10023	afii10051	afii10052	afii10053	afii10054afii10055.altafii10056.alt	afii10057	afii10058	afii10059	afii10060	afii10061	afii10062	afii10145	afii10017	afii10018	afii10019	afii10020	afii10021	afii10022	afii10024	afii10025	afii10026	afii10027	afii10028	afii10029	afii10030	afii10031	afii10032	afii10033	afii10034	afii10035	afii10036	afii10037	afii10038	afii10039	afii10040	afii10041	afii10042	afii10043	afii10044	afii10045	afii10046	afii10047	afii10048	afii10049	afii10065	afii10066	afii10067	afii10068	afii10069	afii10070	afii10072	afii10073	afii10074	afii10075	afii10076	afii10077	afii10078	afii10079	afii10080	afii10081	afii10082	afii10083	afii10084	afii10085	afii10086	afii10087	afii10088	afii10089	afii10090	afii10091	afii10092	afii10093	afii10094	afii10095	afii10096	afii10097	afii10071	afii10099	afii10100	afii10101	afii10102	afii10103	afii10104	afii10105	afii10106	afii10107	afii10108	afii10109	afii10110	afii10193	afii10050	afii10098WgravewgraveWacutewacute	Wdieresis	wdieresisYgraveygrave	afii00208underscoredblquotereversedminutesecond	exclamdbl	nsuperior	afii08941pesetaEuro	afii61248	afii61289	afii61352	estimated	oneeighththreeeighthsfiveeighthsseveneighthsuniFB01uniFB02cyrillicbrevedotlessjcaroncommaaccentcommaaccentcommaaccentrotatezerosuperiorfoursuperiorfivesuperiorsixsuperiorsevensuperioreightsuperiorninesuperioruni2000uni2001uni2002uni2003uni2004uni2005uni2006uni2007uni2008uni2009uni200Auni200BuniFEFFuniFFFCuniFFFDuni01F0uni02BCuni03D1uni03D2uni03D6uni1E3Euni1E3Funi1E00uni1E01uni1F4Duni02F3	dasiaoxiauniFB03uniFB04OhornohornUhornuhornuni0300uni0301uni0303hookdotbelowuni0400uni040Duni0450uni045Duni0460uni0461uni0462uni0463uni0464uni0465uni0466uni0467uni0468uni0469uni046Auni046Buni046Cuni046Duni046Euni046Funi0470uni0471uni0472uni0473uni0474uni0475uni0476uni0477uni0478uni0479uni047Auni047Buni047Cuni047Duni047Euni047Funi0480uni0481uni0482uni0483uni0484uni0485uni0486uni0488uni0489uni048Auni048Buni048Cuni048Duni048Euni048Funi0492uni0493uni0494uni0495uni0496uni0497uni0498uni0499uni049Auni049Buni049Cuni049Duni049Euni049Funi04A0uni04A1uni04A2uni04A3uni04A4uni04A5uni04A6uni04A7uni04A8uni04A9uni04AAuni04ABuni04ACuni04ADuni04AEuni04AFuni04B0uni04B1uni04B2uni04B3uni04B4uni04B5uni04B6uni04B7uni04B8uni04B9uni04BAuni04BBuni04BCuni04BDuni04BEuni04BFuni04C0.altuni04C1uni04C2uni04C3uni04C4uni04C5uni04C6uni04C7uni04C8uni04C9uni04CAuni04CBuni04CCuni04CDuni04CEuni04CF.altuni04D0uni04D1uni04D2uni04D3uni04D4uni04D5uni04D6uni04D7uni04D8uni04D9uni04DAuni04DBuni04DCuni04DDuni04DEuni04DFuni04E0uni04E1uni04E2uni04E3uni04E4uni04E5uni04E6uni04E7uni04E8uni04E9uni04EAuni04EBuni04ECuni04EDuni04EEuni04EFuni04F0uni04F1uni04F2uni04F3uni04F4uni04F5uni04F6uni04F7uni04F8uni04F9uni04FAuni04FBuni04FCuni04FDuni04FEuni04FFuni0500uni0501uni0502uni0503uni0504uni0505uni0506uni0507uni0508uni0509uni050Auni050Buni050Cuni050Duni050Euni050Funi0510uni0511uni0512uni0513uni1EA0uni1EA1uni1EA2uni1EA3uni1EA4uni1EA5uni1EA6uni1EA7uni1EA8uni1EA9uni1EAAuni1EABuni1EACuni1EADuni1EAEuni1EAFuni1EB0uni1EB1uni1EB2uni1EB3uni1EB4uni1EB5uni1EB6uni1EB7uni1EB8uni1EB9uni1EBAuni1EBBuni1EBCuni1EBDuni1EBEuni1EBFuni1EC0uni1EC1uni1EC2uni1EC3uni1EC4uni1EC5uni1EC6uni1EC7uni1EC8.altuni1EC9uni1ECA.altuni1ECBuni1ECCuni1ECDuni1ECEuni1ECFuni1ED0uni1ED1uni1ED2uni1ED3uni1ED4uni1ED5uni1ED6uni1ED7uni1ED8uni1ED9uni1EDAuni1EDBuni1EDCuni1EDDuni1EDEuni1EDFuni1EE0uni1EE1uni1EE2uni1EE3uni1EE4uni1EE5uni1EE6uni1EE7uni1EE8uni1EE9uni1EEAuni1EEBuni1EECuni1EEDuni1EEEuni1EEFuni1EF0uni1EF1uni1EF4uni1EF5uni1EF6uni1EF7uni1EF8uni1EF9uni20ABuni030FcircumflexacutecombcircumflexgravecombcircumflexhookcombcircumflextildecombbreveacutecombbrevegravecombbrevehookcombbrevetildecombcyrillichookleftcyrillicbighookUCcyrillicbighookLCone.pnumzero.osone.ostwo.osthree.osfour.osfive.ossix.osseven.oseight.osnine.osffuni2120Tcedillatcedillag.altgcircumflex.alt
gbreve.altgdot.altgcommaaccent.altItildeImacronIbreveIogonekIJ	IotatonosIotaIotadieresis	afii10055	afii10056uni04C0uni04CFuni1EC8uni1ECA     
��               5 77 ;[ ]v ��       
            
 nZ latn   MOL  (ROM  B  �� 	            �� 
   	         �� 
   
        liga �liga �liga �lnum �lnum �lnum �locl �locl �onum �onum �onum �pnum �pnum �pnum �salt �salt �salt �ss01 �ss01 �ss01 �ss02 �ss02 �ss02 �ss03 �ss03 �ss03 �tnum �tnum �tnum �    	                                      
  < | � � � �.P        �����   J � � � �       .  , � � � � � � � � � �Zgw����EG  ��         p              
����������         �� 	       n          <��       ��  �        
 �          ��          �� !  $%IJ       6       " (^  I O]  I L�  I5  O4  L   I  [gd_resource type="DynamicFont" load_steps=2 format=2]

[ext_resource path="res://Loader/UI/OpenSans-Bold.ttf" type="DynamicFontData" id=1]

[resource]
size = 20
font_data = ExtResource( 1 )
extends Node

signal init (data);
signal spinstart (data);
signal spindata (data);
signal error (data);
signal close (data);
signal skip (data);
signal set_stake (stake);
signal focused (data);
signal unfocused (data);

var enabled : bool;

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS;
	
	enabled = OS.has_feature('JavaScript');
	if(!enabled): return;
		
	JavaScript.eval("""
		if(window.Elysium == null) window.Elysium = {};
		window.Elysium.Game = {
			OutputEvent : "reserved",
			KeepAliveEvent : new Event('elysiumgamekeepalive'),
			ReadyEvent : new Event('elysiumgameready'),
			InputArray : [],
			InputProcessedEvent : "reserved",
			FPS: 0
		}
	""",true);
	
	JavaScript.eval("""window.dispatchEvent(window.Elysium.Game.ReadyEvent)""", true);
	
func _process(delta):
	if(!enabled): return;
	JavaScript.eval("""
		window.dispatchEvent(window.Elysium.Game.KeepAliveEvent);
		window.Elysium.Game.FPS = %s;
	""" % Performance.get_monitor(Performance.TIME_FPS), true);
	
	for i in range(JavaScript.eval("""window.Elysium.Game.InputArray.length""", true)):
		_process_js_input();
		
func process_params(params):
	yield(Globals,"allready");
	for param in params:
		if(param[0] == "token"):
			Globals.singletons["Networking"].set_token(param[1]);
		elif(param[0]=="language"):
			Globals.set_language(param[1]);
		elif(param[0]=="mode"):
			Globals.singletons["Networking"].set_mode(param[1]);
		elif(param[0]=="wallet"):
			Globals.singletons["Networking"].set_wallet(param[1]);
		elif(param[0]=="currency"):
			Globals.set_currency(param[1]);
		elif(param[0]=="operator"):
			Globals.singletons["Networking"].set_operator(param[1]);
		elif(param[0]=="debug"):
			Globals.set_debug(param[1]);
		elif(param[0]=="jurisdiction"):
			Globals.set_jurisdiction(param[1]);
		
func output(data, event="elysiumgameoutput"):
	if(!enabled): return;
	prints(data, event);
	JavaScript.eval("""
		window.Elysium.Game.OutputEvent = new CustomEvent("%s", {detail: { data: `%s` }});
		window.dispatchEvent(window.Elysium.Game.OutputEvent)
	""" % [event, data], true);
		
func _process_js_input():
	var input = JavaScript.eval("""
		window.Elysium.Game.InputArray.shift()
	""", true);
	prints("Received input from JS", input);
	var data = JSON.parse(input);
	if(data.error > 0):
		JavaScript.eval("""
			window.Elysium.Game.InputProcessedEvent = new CustomEvent('elysiumgameinputprocessed', { input: '%s', success: false });
			window.dispatchEvent(window.Elysium.Game.InputProcessedEvent)
		""" % input, true);
		prints("Failed to process JS input!");
	else:
		prints(data.result["type"], data.result["data"]);
		emit_signal(data.result["type"], data.result["data"]);
		JavaScript.eval("""
			window.Elysium.Game.InputProcessedEvent = new CustomEvent('elysiumgameinputprocessed', { input: '%s', success: true });
			window.dispatchEvent(window.Elysium.Game.InputProcessedEvent)
		""" % input, true);
		prints("Input from JS processed");
		
func play_sound(sfx, volume=1):
	if(!enabled): return;
	JavaScript.eval("""
		window.Elysium.SoundEngine.play("%s", %s);
	""" % [sfx, volume], true);

func play_sound_after(sfx, delay, volume=1):
	if(!enabled): return;
	JavaScript.eval("""
		window.Elysium.SoundEngine.volume("%s", %s);
		window.Elysium.SoundEngine.playAfter("%s", %s);
	""" % [sfx, volume, sfx, delay], true);

func loop_sound(sfx, volume=1):
	if(!enabled): return;
	JavaScript.eval("""
		window.Elysium.SoundEngine.volume("%s", %s);
		window.Elysium.SoundEngine.loop("%s");
	""" % [sfx, volume, sfx], true);
	
func stop_sound(sfx):
	if(!enabled): return;
	JavaScript.eval("""
		window.Elysium.SoundEngine.stop("%s");
	""" % sfx, true);
	
func pause_sound(sfx):
	if(!enabled): return;
	JavaScript.eval("""
		window.Elysium.SoundEngine.pause("%s");
	""" % sfx, true);

func fade_sound(sfx, from, to, duration, stopOnZero):
	if(!enabled): return;
	JavaScript.eval("""
		window.Elysium.SoundEngine.fade("%s", %s, %s, %s, %s);
	""" % [sfx, from, to, duration, stopOnZero], true);

func fade_sound_to(sfx, to, duration, stopOnZero):
	if(!enabled): return;
	JavaScript.eval("""
		window.Elysium.SoundEngine.fadeTo("%s", %s, %s, %s);
	""" % [sfx, to, duration, stopOnZero], true);

func fade_track(track, from, to, duration, stopOnZero):
	if(!enabled): return;
	JavaScript.eval("""
		window.Elysium.SoundEngine.fadeTrack("%s", %s, %s, %s);
	""" % [track, from, to, duration, stopOnZero], true);

func fade_to_track(track, to, duration, stopOnZero):
	if(!enabled): return;
	JavaScript.eval("""
		window.Elysium.SoundEngine.fadeToTrack("%s", %s, %s, %s);
	""" % [track, to, duration, stopOnZero], true);

func change_track(track, sound, transition, loop, level, stop_previous):
	if(!enabled): return;
	JavaScript.eval("""
		window.Elysium.SoundEngine.changeTrack("%s", "%s", %s, %s, %s, %s);
	""" % [track, sound, transition, loop, level, stop_previous], true);

func get_path():
	if(!enabled): return null;
	
	var index_location = JavaScript.eval(""" window.location.origin+window.location.pathname """, true);
	var game_location =  JavaScript.eval("""
		(window.Elysium.initConfig && window.Elysium.initConfig.game && window.Elysium.initConfig.game.location) || ""
	""", true);
	var path = index_location if (game_location == "" || game_location == "./") else game_location;

	if(path.ends_with(".html")):
		path = path.replace(path.split("/", false)[-1], "");
	
	return path;
extends Node;

var awaiting_count = 0;
var results = [];

signal completed;

static func resolve(res = null):
	var promise = Promise.duplicate();
	promise.call_deferred("_resolve", res);

	return yield(promise, "completed");

static func race(coroutines: Array):
	var promise = Promise.duplicate();
	for coroutine in coroutines:
		if coroutine.is_valid():
			coroutine.connect("completed", promise, "_resolve");
			
	return promise;

static func all(coroutines: Array):
	var promise = Promise.duplicate();

	for i in range(coroutines.size()):
		var coroutine = coroutines[i];
		promise.awaiting_count += 1;
		promise.results.append(null);

		if coroutine.is_valid():
			coroutine.connect("completed", promise, "_resolve_all", [i]);
		else:
			promise._resolve_all(null, i);

	return promise;

func _resolve(res = null):
	emit_signal("completed", res);

func _resolve_all(res = null, pos = 0):
	awaiting_count -= 1;
	results[pos] = res;

	if(awaiting_count == 0): 
		emit_signal("completed", results);
ECFG@      _global_script_classes�                    class         AssetLoader       language      GDScript      path      res://Loader/AssetLoader.gd       base      Node            class         Fader         language      GDScript      path      res://Main/Misc/Fader.gd      base      Control             class         FallingReel       language      GDScript      path      res://Main/Slot/FallingReel.gd        base      Reel            class         Game      language      GDScript      path      res://Main/Game.gd        base      Node            class         LoadingSystem         language      GDScript      path      res://Loader/LoadingSystem.gd         base      Node            class         PackageExporter       language      GDScript      path      res://Loader/PackageExporter.gd       base      Node            class         PackageLoader         language      GDScript      path      res://Loader/PackageLoader.gd         base      Node            class         Reel      language      GDScript      path      res://Main/Slot/Reel.gd       base      Node2D              class         ReelSpinning      language      GDScript      path      res://Main/Slot/ReelSpinning.gd       base      Reel            class         SpineSpriteExtension      language      GDScript      path   "   res://Main/SpineSpriteExtension.gd        base      SpineSprite             class         Stateful      language      GDScript      path   $   res://Main/Slot/Features/Stateful.gd      base      Node            class         Tile      language      GDScript      path      res://Main/Slot/Tile.gd       base      Node2D              class         TileData      language      GDScript      path      res://Main/Slot/TileData.gd       base      Object              class         TileDescription       language      GDScript      path   "   res://Main/Slot/TileDescription.gd        base      Resource            class         VFSM      language      GDScript      path   #   res://addons/visual_fsm/fsm/vfsm.gd       base      Resource            class         VFSMSingleton         language      GDScript      path   )   res://addons/visual_fsm/vfsm_singleton.gd         base      Node            class      	   VFSMState         language      GDScript      path   )   res://addons/visual_fsm/fsm/vfsm_state.gd         base      Resource            class         VFSMStateBase         language      GDScript      path   4   res://addons/visual_fsm/resources/vfsm_state_base.gd      base      Object              class         VFSMStateNode         language      GDScript      path   7   res://addons/visual_fsm/editor/vfsm_state_graph_node.gd       base   	   GraphNode               class         VFSMTrigger       language      GDScript      path   +   res://addons/visual_fsm/fsm/vfsm_trigger.gd       base      Resource            class         VFSMTriggerAction         language      GDScript      path   2   res://addons/visual_fsm/fsm/vfsm_trigger_action.gd        base      VFSMTrigger             class         VFSMTriggerBase       language      GDScript      path   6   res://addons/visual_fsm/resources/vfsm_trigger_base.gd        base      Object              class         VFSMTriggerGraphSlot      language      GDScript      path   9   res://addons/visual_fsm/editor/vfsm_trigger_graph_slot.gd         base      PanelContainer              class         VFSMTriggerScript         language      GDScript      path   2   res://addons/visual_fsm/fsm/vfsm_trigger_script.gd        base      VFSMTrigger             class         VFSMTriggerTimer      language      GDScript      path   1   res://addons/visual_fsm/fsm/vfsm_trigger_timer.gd         base      VFSMTrigger             class         WinTile       language      GDScript      path   #   res://Main/Slot/Features/WinTile.gd       base      Node   _global_script_class_icons�              LoadingSystem                PackageLoader                SpineSpriteExtension             VFSMStateNode                VFSMTriggerBase              VFSM             VFSMTriggerGraphSlot             WinTile              FallingReel              PackageExporter           	   VFSMState                VFSMTriggerScript                ReelSpinning             Tile             VFSMTriggerAction                AssetLoader              VFSMSingleton                Reel             Stateful             TileData             VFSMStateBase                VFSMTrigger              VFSMTriggerTimer             Fader                Game             TileDescription           application/config/name         BattleOfMyths      application/run/main_scene(         res://Loader/LoadingScene.tscn      application/boot_splash/fullsize          "   application/boot_splash/use_filter              application/boot_splash/bg_color                    �?   application/config/icon             autoload/Globals          *res://Loader/Globals.gd   autoload/JS$         *res://Loader/JSComms/JS.gd    autoload/Promise          *res://Loader/Promise.gd   autoload/Mapper          *res://Loader/Mapper.gd    debug/gdscript/warnings/enable             display/window/size/width            display/window/size/height            display/window/stretch/mode         2d     display/window/stretch/aspect         expand     editor_plugins/enabled�         '   res://addons/BitmapFontEasy/plugin.cfg  $   res://addons/tool_button/plugin.cfg #   res://addons/visual_fsm/plugin.cfg     gui/theme/custom_font,      $   res://Loader/UI/default_dynfont.tres   importer_defaults/wavD               compress/mode            
   force/mono           importer_defaults/textureP               compress/lossy_quality    �������?   	   detect_3d             input/ui_accept�              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device            alt           shift             control           meta          command           pressed           scancode        physical_scancode             unicode           echo          script            InputEventKey         resource_local_to_scene           resource_name             device            alt           shift             control           meta          command           pressed           scancode        physical_scancode             unicode           echo          script            InputEventJoypadButton        resource_local_to_scene           resource_name             device            button_index          pressure          pressed           script      
   input/skip              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device            alt           shift             control           meta          command           pressed           scancode          physical_scancode             unicode           echo          script            InputEventMouseButton         resource_local_to_scene           resource_name             device            alt           shift             control           meta          command           button_mask           position              global_position               factor       �?   button_index         pressed           doubleclick           script      
   input/spin�              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device            alt           shift             control           meta          command           pressed           scancode          physical_scancode             unicode           echo          script         input/spinforce�              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device            alt           shift             control           meta          command           pressed           scancode        physical_scancode             unicode           echo          script      3   network/limits/debugger_stdout/max_chars_per_second          )   physics/common/enable_pause_aware_picking         $   rendering/quality/driver/driver_name         GLES2   7   rendering/quality/intended_usage/framebuffer_allocation          >   rendering/quality/intended_usage/framebuffer_allocation.mobile          %   rendering/vram_compression/import_etc         &   rendering/vram_compression/import_etc2          :   rendering/misc/lossless_compression/webp_compression_level         )   rendering/quality/directional_shadow/size         0   rendering/quality/directional_shadow/size.mobile         #   rendering/quality/shadow_atlas/size         *   rendering/quality/shadow_atlas/size.mobile         +   rendering/quality/shadow_atlas/cubemap_size      @   0   rendering/quality/shadow_atlas/quadrant_0_subdiv          0   rendering/quality/shadow_atlas/quadrant_1_subdiv          0   rendering/quality/shadow_atlas/quadrant_2_subdiv          0   rendering/quality/shadow_atlas/quadrant_3_subdiv          %   rendering/quality/shadows/filter_mode          7   rendering/quality/reflections/texture_array_reflections          .   rendering/quality/reflections/high_quality_ggx          1   rendering/quality/reflections/irradiance_max_size          .   rendering/quality/shading/force_vertex_shading         3   rendering/quality/shading/force_lambert_over_burley         .   rendering/quality/shading/force_blinn_over_ggx         2   rendering/quality/filters/anisotropic_filter_level         3   rendering/quality/filters/use_nearest_mipmap_filter         &   rendering/2d/opengl/batching_send_null         0   rendering/gles2/compatibility/disable_half_float         )   rendering/environment/default_clear_color                    �?(   rendering/quality/reflections/atlas_size          *   rendering/quality/reflections/atlas_subdiv          "   rendering/quality/filters/use_fxaa         "   rendering/quality/depth/hdr.mobile         )   rendering/environment/default_environment(         res://Loader/default_env.tres   3   rendering/quality/lightmapping/use_bicubic_sampling          7   rendering/cpu_lightmapper/quality/low_quality_ray_count          :   rendering/cpu_lightmapper/quality/medium_quality_ray_count          8   rendering/cpu_lightmapper/quality/high_quality_ray_count          9   rendering/cpu_lightmapper/quality/ultra_quality_ray_count          