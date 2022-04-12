extends Control

var current_multiplier = 0;
var rounds = [];
var winmap = {
	1 : 1,
	2 : 2,
	3 : 3
};
var losemap = {
	1 : 2,
	2 : 3,
	3 : 1
};
var evenmap = {
	1 : 3,
	2 : 1,
	3 : 2
};

signal anim_end;

var shown := false;
var active := false;
var is_char_selected := false;
var other_element_sprite : Sprite;
var counter_text;
var current_team : String;
var current_char;
var current_opponent;

var center_counter_shown : bool = false;
var center_counter_amount : int;
var maxwin : bool = false;
var totalmultiplier : int = 0;

func _ready():
	VisualServer.canvas_item_set_z_index(get_canvas_item(), 20)
	#VisualServer.canvas_item_set_z_index($ViewportContainer.get_canvas_item(), 21)
	
	set_process_input(true);
	#counter_text = $Centering/CounterText;
	Globals.register_singleton("Bonus", self);
	yield(Globals, "allready")
	Globals.connect("resolutionchanged", self, "on_resolution_changed");
	#$ViewportContainer.set_as_toplevel(true);
	
func on_resolution_changed(landscape, portrait, screenratio, zoom):	
	var il = inverse_lerp(438.0, 1024.0, OS.window_size.x);
	
func has_feature(data):
	if(!data.has("features")): return false;
	for feature in data["features"]:
		if(feature["type"] == "InstaWin"): 
			return true;
	return false;
			
func get_wins():
	var data = Globals.singletons["Networking"].lastround;
	if(data == null): return 0;
	if(!("wins" in data)): return 0;
	for win in data["wins"]:
		if(!win.has("winline")): continue;
		if(int(win["winline"]) == -1): return float(win["win"]);
	return 20; #DEBUG

func get_payouts():
	var data = Globals.singletons["Networking"].lastround;
	for feature in data["features"]:
		if(feature["type"] == "InstaWin"): 
			return feature.data.payouts;
	return [5,10,13,16,23,40,120,400,1000]; #DEBUG

func activate(totalmultiplier, override=false):
	var available_multipliers = get_payouts();
	prints(available_multipliers)
	self.totalmultiplier = totalmultiplier;
	
	maxwin = totalmultiplier == available_multipliers[-1];
	shown = true;
	is_char_selected = false;
	
	current_multiplier = 0;
	totalmultiplier = int(totalmultiplier);
	var n = 0;
	while(totalmultiplier > n):
		var i = available_multipliers.pop_front();
		rounds.append(i-n)
		n += i-n;
				
	prints("Rounds",rounds);
	
	var state = Globals.singletons["Stateful"].state;
	if(override):
		current_team = override;
	else:
		if(int(state.counter2) >= int(state.max2)): 
			print("Light team");
			current_team = "Light";
		if(int(state.counter1) >= int(state.max1)):
			print("Dark team");
			current_team = "Dark";
			
	Globals.singletons["BarBlue"].target_amount = 0.0;
	Globals.singletons["BarGreen"].target_amount = 0.0;

	for chr in get_characters("Light"):
		chr.z_index = chr.default_z_index;
		chr.character_play("bonus-idle");
		
	for chr in get_characters("Dark"):
		chr.z_index = chr.default_z_index;
		chr.character_play("bonus-idle");
		
	$Centering/Logo.visible = false;
	$Centering/Logo2.visible = false;
	
	$Centering/Game/Positions/DuelCenter/Left/SpineSprite.modulate = Color.transparent;
	$Centering/Game/Positions/DuelCenter/Right/SpineSprite.modulate = Color.transparent;
	if(current_team == "Light"):
		other_element_sprite = $Centering/Game/Positions/DuelCenter/Left/SpineSprite/Sprite;
		$Centering/Logo2/Logo.set_skin("LightWizardz");
		$Centering/Logo/Logo.set_skin("Blue");
		color_characters("Dark", Color.transparent, 0.0);
		color_characters("Light", Color.transparent, 0.0);
	elif(current_team == "Dark"):
		other_element_sprite = $Centering/Game/Positions/DuelCenter/Right/SpineSprite/Sprite;
		$Centering/Logo2/Logo.set_skin("DarkWizardz");
		$Centering/Logo/Logo.set_skin("Green");
		color_characters("Light", Color.transparent, 0.0);
		color_characters("Dark", Color.transparent, 0.0);

	#boss_health = floor((totalmultiplier/3) + randi()%(totalmultiplier/3));
	center_counter_amount = 0;
	center_counter_shown = false;
	Globals.singletons["Audio"].change_track("background", "BonusTheme", 1000, 1, 1, 0);
	Globals.singletons["Audio"].fade_to("MainThemeMelody", 0, 500, 0);
	
	Globals.singletons["Audio"].play("BonusIntro");
	$Top/AnimationPlayer.play("RESET");	
	$AnimationPlayer.play("RESET");
	yield($AnimationPlayer, "animation_finished")
	$AnimationPlayer.play("Show");
	yield($AnimationPlayer, "animation_finished")
	$Centering/Logo.visible = true;
	$Centering/Logo2.modulate = Color.transparent;
	$Centering/Logo2.visible = true;
	$Centering/Logo/Logo.play_anim_then_loop("popup", "close");

	yield($Centering/Logo/Logo, "animation_complete");
#	yield($Centering/Logo/Logo, "animation_complete");
	if(current_team == "Light"):
		Globals.singletons["Audio"].play("LightWizardzEmblem");
	elif(current_team == "Dark"):
		Globals.singletons["Audio"].play("DarkWizardzEmblem");
	$Centering/Logo.visible = false;	
	$Centering/Logo2/Logo.set_timescale(1.0);
	$Centering/Logo2/Logo.play_anim_then_loop("popup", "idle");
	yield(get_tree(), "idle_frame");
	$Centering/Logo2.modulate = Color.white;
	yield($Centering/Logo2/Logo, "animation_complete")
	$Centering/Logo2/Logo.set_timescale(0.25);
	yield(get_tree().create_timer(2.0), "timeout");
	$AnimationPlayer.play("MoveLogo");


	#on_play_button_pressed();
#func on_play_button_pressed():
	#$ClickWaiter.visible = false;
	if(current_team == "Light"):
		color_characters("Light", Color.white, 1.0);
		move_characters("Light", "Intro", 0.0); 
	elif(current_team == "Dark"):
		color_characters("Dark", Color.white, 1.0);
		move_characters("Dark", "Intro", 0.0);
	yield($AnimationPlayer, "animation_finished")
	$Centering/Explanation/AnimationPlayer.play("Show");
	start_selection();

func start_selection():
	var spinesprite;
	var sprite;
	if(current_team == "Light"): 
		spinesprite = $Centering/Game/Positions/DuelCenter/Left/SpineSprite;
	elif(current_team == "Dark"): 
		spinesprite = $Centering/Game/Positions/DuelCenter/Right/SpineSprite;
	spinesprite.modulate = Color.transparent;
	other_element_sprite.modulate = Color.transparent;
	$AnimationPlayer.play("ShowChooseElement");
	for chr in get_characters(current_team):
		chr.show_element();
		chr.z_index = chr.default_z_index + 2;
		
	move_characters(current_team, "Choose1", 1.0);

	yield(get_tree().create_timer(1.0), "timeout");
	is_char_selected = false;
	for chr in get_characters(current_team):
		chr.show();
		chr.enable_click();
		chr.connect("pressed", self, "char_selected", [chr])

func char_selected(selected):
	if(is_char_selected): return;
	$AnimationPlayer.play("HideChooseElement");
	is_char_selected = true;
	current_char = selected;
	for chr in get_characters(current_team):
		chr.disconnect("pressed", self, "char_selected");
		if(chr == selected): 
			chr.selected();
			chr.z_index = chr.default_z_index + 3;
		else:
			chr.hide_element();
			chr.hide();

	yield(get_tree().create_timer(1.0), "timeout");
	for chr in get_characters(current_team):
		if(chr == selected): 
			if(current_team == "Light"):
				move_character(current_team, chr.id-1, "DuelCenter/Right");
			else:
				move_character(current_team, chr.id-1, "DuelCenter/Left");
		else:
			if(current_team == "Light"):
				move_character(current_team, chr.id-1, "ShuffleRight/"+str(chr.id));
			else:
				move_character(current_team, chr.id-1, "ShuffleLeft/"+str(chr.id));
			
	#Globals.singletons["Audio"].play("Hero "+str(id));
	yield(get_tree().create_timer(0.5), "timeout");
	for chr in get_characters(current_team):
		if(chr != selected): chr.z_index = chr.default_z_index
	yield(get_tree().create_timer(0.5), "timeout");
	if(current_team == "Light"):
		color_characters("Dark", Color.transparent, 0.0);
		color_characters("Dark", Color.gray, 1.0);
		move_characters("Dark", "ShuffleLeft", 0.0);
	elif(current_team == "Dark"):
		color_characters("Light", Color.transparent, 0.0);
		color_characters("Light", Color.gray, 1.0);
		move_characters("Light", "ShuffleRight", 0.0);

	$AnimationPlayer.play("ShowDuelFx");
	yield(get_tree().create_timer(1.0), "timeout");

	active = true;
	var win = len(rounds) > 0;
	
	if(current_team == "Light"):
		shuffle_animation("Dark", win);
	elif(current_team == "Dark"):
		shuffle_animation("Light", win);
		
func shuffle_animation(team, win):	
	var target = (3 + (randi()%4))*3;
	Globals.singletons["Audio"].play("Anticipation");
	if(win):
		target+=winmap[current_char.id];
	else:
		target+=losemap[current_char.id];
		
	$Tween.remove_all();
	$Tween.interpolate_method(
		self, "shuffle_animation_frame", 
		0.0, target, 3.6, 
		Tween.TRANS_CUBIC, Tween.EASE_OUT, 0.0)
	$Tween.start();
	yield($Tween, "tween_all_completed");
	var spinesprite;
	var sprite;
	if(current_team == "Light"): 
		spinesprite = $Centering/Game/Positions/DuelCenter/Left/SpineSprite;
		sprite = $Centering/Game/Positions/DuelCenter/Left/Sprite;
		$Centering/Game/Positions/DuelCenter/Left/SpineSprite/Sprite.texture = current_opponent.elementtex;
	elif(current_team == "Dark"): 
		spinesprite = $Centering/Game/Positions/DuelCenter/Right/SpineSprite;
		sprite = $Centering/Game/Positions/DuelCenter/Right/Sprite;
		$Centering/Game/Positions/DuelCenter/Right/SpineSprite/Sprite.texture = current_opponent.elementtex;
				
	var opponent_spinesprite = current_opponent.get_node("Character");
	spinesprite.set_new_state_data(opponent_spinesprite.animation_state_data_res, opponent_spinesprite.skin)
	spinesprite.play_anim("bonus-idle", true);
	other_element_sprite.texture = current_opponent.elementtex;
	other_element_sprite.modulate = Color.white;
	$Tween.remove_all();
	$Tween.interpolate_property(
		spinesprite, "modulate", 
		Color.transparent, Color.white, 1.0, 
		Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.0)
	$Tween.interpolate_property(
		sprite, "modulate", 
		Color.white, Color.transparent, 1.0, 
		Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.0)
	$Tween.start();
	
	yield($Tween, "tween_all_completed");
	$AnimationPlayer.play("HideDuelFx");
	yield(get_tree().create_timer(1.0), "timeout");
	current_opponent.unhighlight();
	if(win):
		current_char.hide_element();
		$Tween.interpolate_property(
			other_element_sprite, "modulate", 
			Color.white, Color.transparent, 1.0, 
			Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.0)
		$Tween.start();
		if(current_team == "Light"):
			Globals.singletons["Audio"].play_after("YouWinLight", 700);
		elif(current_team == "Dark"):
			Globals.singletons["Audio"].play_after("YouWinDark", 300);
		yield(get_tree().create_timer(1.0), "timeout");	
		spinesprite.play_anim("bonus-close", false);
		current_char.get_character().play_anim_then_loop("bonus-popup", "bonus-idle");
		yield(get_tree().create_timer(1.0), "timeout");
		var middle = $Centering/Game/Positions/DuelCenter/Center;
		$Tween.interpolate_property(
			current_char, "global_position", 
			current_char.global_position, middle.global_position, 0.5, 
			Tween.TRANS_QUAD, Tween.EASE_IN_OUT, 0.0)
		$Tween.start();
		yield(get_tree().create_timer(1.0), "timeout");
		var winmult = rounds.pop_front();
		bangup_multiplier(winmult);
		yield(get_tree().create_timer(2.0), "timeout");
		if(current_team == "Light"):
			color_characters("Dark", Color.transparent, 1.0);
			move_characters("Dark", "ShuffleLeft", 0.0);
		elif(current_team == "Dark"):
			color_characters("Light", Color.transparent, 1.0);
			move_characters("Light", "ShuffleRight", 0.0);
		yield(get_tree().create_timer(1.0), "timeout");
		current_char.character_play("bonus-idle", true);
		if(maxwin  && len(rounds) == 0):
			yield(get_tree().create_timer(1.0), "timeout");
			reached_end();
		else:
			start_selection();
	else:
		# loosing animation
		spinesprite.play_anim("bonus-popup", false);
		Globals.singletons["Audio"].play_after("Disappear", 300);
		current_char.character_play("bonus-close", false);
		current_char.hide_element();
		yield(get_tree().create_timer(1.0), "timeout");

		reached_end();
	
func shuffle_animation_frame(n):
	var chars;
	if(current_team == "Light"): chars = get_characters("Dark");
	elif(current_team == "Dark"): chars = get_characters("Light");
	var chosen = int(ceil(n))%3;
	for i in range(3): 
		if(i==chosen): 
			current_opponent = chars[i];
			chars[i].highlight();
			if(current_team == "Light"): 
				$Centering/Game/Positions/DuelCenter/Left/Sprite.texture = chars[i].centertex;
				$Centering/Game/Positions/DuelCenter/Left/Sprite.modulate = Color.white;
			elif(current_team == "Dark"): 
				$Centering/Game/Positions/DuelCenter/Right/Sprite.texture = chars[i].centertex;
				$Centering/Game/Positions/DuelCenter/Right/Sprite.modulate = Color.white;
		else: 
			chars[i].unhighlight();
		
func reached_end():
	$Centering/EndBangup/Center/CounterLabel.text = "x"+str(totalmultiplier);
	$Centering/EndBangup/Center/CounterLabel.rect_pivot_offset = $Centering/EndBangup/Center/CounterLabel.rect_size/2;
	$Centering/EndBangup/Center/CounterLabel.rect_position = -$Centering/EndBangup/Center/CounterLabel.rect_size/2 + Vector2.RIGHT * 50;
	$Centering/EndBangup/AnimationPlayer.play("Show");
	$Top/AnimationPlayer.play("Hide");
	Globals.singletons["Audio"].play("Glitter",0.5);
	yield($Centering/EndBangup/AnimationPlayer, "animation_finished");
	#yield(get_tree().create_timer(1.0), "timeout");
	$Centering/Explanation/AnimationPlayer.play("Hide");
	$AnimationPlayer.play("Hide");
	
	#Globals.singletons["WinBar"].set_text(float(get_wins()), false);
	emit_signal("anim_end");
	active = false;
	shown = false;	

func bangup_multiplier(amount):	
	$Centering/BangupNumber/CounterLabel.text = "x"+str(amount);
	$Centering/BangupNumber/CounterLabel.rect_pivot_offset = $Centering/BangupNumber/CounterLabel.rect_size/2;
	$Centering/BangupNumber/CounterLabel.rect_position = -$Centering/BangupNumber/CounterLabel.rect_size/2;
	$Centering/BangupNumber.global_position = $Centering/Game/Positions/DuelCenter/Center.global_position;
	
	$Centering/BangupNumber/AnimationPlayer.play("Show");
	Globals.singletons["Audio"].play("Mult1",0.5);
	yield(get_tree().create_timer(1.0), "timeout");
	$Centering/BangupNumber/Tween.interpolate_property(
		$Centering/BangupNumber, "global_position", 
		$Centering/BangupNumber.global_position, $Top/NumberContainer.global_position, 0.5, 
		Tween.TRANS_QUAD, Tween.EASE_IN_OUT, 0.5)
	$Centering/BangupNumber/Tween.start();
	yield($Centering/BangupNumber/Tween, "tween_all_completed");
	Globals.singletons["Audio"].play("Mult2", 0.5);
	$Centering/BangupNumber.modulate = Color.transparent;
	$Top/AnimationPlayer.stop();
	if(current_multiplier == 0):
		$Top/AnimationPlayer.play("Show");
	else:
		$Top/AnimationPlayer.play("Bangup");
		
	current_multiplier += amount;
	$Top/NumberContainer/CounterLabel.text = "x"+str(current_multiplier);
	$Top/NumberContainer/CounterLabel.rect_pivot_offset = $Top/NumberContainer/CounterLabel.rect_size/2;
	$Top/NumberContainer/CounterLabel.rect_position = -$Top/NumberContainer/CounterLabel.rect_size/2 + Vector2.RIGHT * 50;
	#reached_end();

func get_characters(team):
	return get_node("Centering/Game/CharacterContainer"+team).get_children();

func move_characters(team, to, duration=1.0):
	for i in range(3):
		move_character(team, i, to+"/"+str(i+1), duration);

func move_character(team, id, to, duration=1.0):
	var character = get_characters(team)[id];
	var tween = character.get_node("Tween");
	var pos = get_node("Centering/Game/Positions/"+to);
	if(duration == 0.0):
		character.scale = pos.scale;
		character.global_position = pos.global_position;
		return;
	tween.interpolate_property(character, "global_position",
		character.global_position, pos.global_position, duration,
		Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	tween.interpolate_property(character, "scale",
		character.scale, pos.scale, duration,
		Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	tween.start()
	
func color_characters(team, color, duration=1.0):
	for i in range(3):
		color_character(team, i, color, duration);

func color_character(team, id, color, duration=1.0):
	var character = get_characters(team)[id];
	if(duration == 0.0):
		character.modulate = color;
		return;
	var tween = character.get_node("Tween");
	tween.interpolate_property(character, "modulate",
		character.modulate, color, duration,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
