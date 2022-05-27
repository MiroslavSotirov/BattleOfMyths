extends SpineSprite
class_name SpineSpriteExtension

export(Resource) var custom_material;
export(Resource) var custom_material_additive;
export(String) var skin;
export(String) var startanimation;
export(bool) var loop = true;
export(float) var timescale = 1 setget set_timescale;

var current_anim : String;
var currently_looping : bool;

func _ready():
	#get_animation_state().disable_queue();
	if(startanimation): play_anim(startanimation, loop);
	if(skin): set_skin(skin);
	yield(get_tree(), "idle_frame")
	if(custom_material != null || custom_material_additive != null):
		set_children_material();
		
func _process(delta):
	if(custom_material != null || custom_material_additive != null):
		update_children_color();

func set_children_material_param(param, val):
	for child in get_children():
		if(child is SpineSpriteMeshInstance2D):
			if(child.material is CanvasItemMaterial): continue;
			child.material.set_shader_param(param, val);
		
func update_children_color():
	for child in get_children():
		if(child is SpineSpriteMeshInstance2D):
			if(child.material is CanvasItemMaterial): continue;
			var color = child.get_slot().get_data().get_color();
			child.material.set_shader_param("tint", color);
		
func set_children_material():
	for child in get_children():
		if(child is SpineSpriteMeshInstance2D):
			var blend_mode = child.get_slot().get_data().get_blend_mode();
			if(custom_material != null && blend_mode == 0): 
				child.set_material(custom_material.duplicate());
			elif(custom_material_additive != null && blend_mode >= 1):
				child.set_material(custom_material_additive.duplicate());
	
func set_new_state_data(data, newskin=null, playanim=false):
	self.animation_state_data_res = data;
	#yield(VisualServer, "frame_post_draw");
	if(newskin): set_skin(newskin);	
	set_children_material();
	update_children_color();
	reset_pose();
	if(playanim): play_anim(current_anim, currently_looping);
		
func set_skin(skin):
	if(animation_state_data_res == null): return;
	if(animation_state_data_res.skeleton.find_skin(skin) == null):
		if(animation_state_data_res.skeleton.find_skin("EN") != null):
			skin = "EN";
		else:
			skin = "default";
	get_skeleton().set_skin_by_name(skin);

func play_anim(anim, loop, timescale_override=null, has_delay=true):
	current_anim = anim;
	if(animation_state_data_res == null): return;
	if(has_delay): yield(VisualServer, "frame_pre_draw");
	get_skeleton().set_slots_to_setup_pose();
	get_animation_state().clear_tracks();
	get_animation_state().call_deferred("set_animation", current_anim, loop);
	currently_looping = loop;
	if(timescale_override != null): set_timescale(timescale_override, false);
	else: set_timescale(timescale);
	
func play_anim_then_loop(anim, loopanim):
	play_anim(anim, false);
	yield(self, "animation_complete");
	if(current_anim == anim): play_anim(loopanim, true);

func set_timescale(scale, permanent=true):
	scale = float(scale);
	if(get_animation_state()):
		get_animation_state().set_time_scale(scale);
	if(permanent): timescale = scale;

func reset_pose():
	if(get_skeleton()): 
		get_skeleton().set_bones_to_setup_pose();
		get_skeleton().set_slots_to_setup_pose();

