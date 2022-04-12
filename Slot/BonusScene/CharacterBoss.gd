extends Node2D

export (float) var shake := 0.0 setget set_shake;
var enabled := false;
var health := 5;
var clicked := false;

func _ready():
	$AnimationPlayer.play("Show");
	$BossSprite.visible = false;
	$CPUParticles2D.emitting = true;
	$CPUParticles2D2.emitting = true;
	yield($AnimationPlayer, "animation_finished");
	Globals.singletons["FaderBright"].tween(1.0,0.0,0.5);
	$CPUParticles2D.emitting = false;
	$CPUParticles2D2.emitting = false;
	$BossSprite.visible = true;	
	$BossSprite.play_anim("idle", true);
	enabled = true;
	on_resolution_changed(false, false, Globals.screenratio, 0.0);
	Globals.connect("resolutionchanged", self, "on_resolution_changed");
	
func on_resolution_changed(landscape, portrait, screenratio, zoom):
	if(screenratio < 0.5):
		scale = Vector2.ONE;
	else:
		scale = Vector2.ONE * lerp(1.0, 1.6, inverse_lerp(0.5, 1.0, screenratio));
	
func set_shake(n):
	Globals.singletons["BonusFight"].shake = n;
	
func _process(delta):
	position.y = sin((float(OS.get_ticks_msec()*2)/1000.0))*25;
	if(clicked): clicked = false;

func _unhandled_input(event):
	_input(event);

func _input(event):
	if(clicked): return;
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.is_pressed():
			var pos = get_viewport().get_mouse_position();
			if(pos.distance_to(global_position) < 400):
				_on_pressed(pos);
				clicked = true;
		
func _on_pressed(pos):
	if(!enabled): return;
	if(!is_visible_in_tree()): return;
	$BossSprite.play_anim_then_loop("hit","idle");
	$BossSprite.scale.x *= -1;	
	Globals.singletons["BonusFight"].spawn_explosion(pos);
	health -= 1;
	if(health == 0): die();
	else: pass
	
func die():
	enabled = false;
	$CPUParticlesDeath.emitting = true;
	$BossSprite.play_anim("fade", false);
	Globals.singletons["BonusFight"].shake += 1;
	Globals.singletons["FaderBright"].tween(0.25,0.0,0.5);
