extends Node2D

export (PackedScene) var tap_scene;
export (PackedScene) var explosion_scene;
export (float) var shake_lower;
export (NodePath) var background;
var shake := 0.0;

func spawn_explosion(pos):
	var expfx = explosion_scene.instance();
	add_child(expfx);
	expfx.global_scale = Vector2.ONE;
	expfx.global_position = pos;
	shake += 0.1;
		
func _process(delta):
	if(!is_visible_in_tree()): return;
	
	get_node("../MaskContainer").global_transform.origin = \
			Vector3(randf() * shake, randf() * shake, 0);
	
	get_node(background).position = Vector2(randf() * shake, randf() * shake) * 100.0;
	
	position = Vector2(randf() * shake, randf() * shake) * 100.0;
	
	shake = lerp(shake, 0, shake_lower * delta);
