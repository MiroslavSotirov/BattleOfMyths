extends Node
class_name Game

var round_closed : bool = false;
var round_ended : bool = true;
var freespins : int = 0;
var increase_fs : bool = false;
var in_freespins : bool = false;
var fs_ended : bool = false;

var features = [];
var timer: Timer = Timer.new();

signal ready_to_close_round;

func _ready():
	Globals.register_singleton("Game", self);
#	Globals.singletons["Fader"].tween(1,1,0);
#	Globals.register_singleton("Game", self);
#	yield(Globals, "allready")
#	Globals.singletons["Stateful"].connect("new_state", self, "update_state")
#	yield(get_tree(),"idle_frame")
#	JS.connect("init", Globals.singletons["Networking"], "init_received");
#	Globals.singletons["Networking"].connect("initcomplete", self, "init_data_received");

func init_data_received():
	round_closed = true; #Init should close previous round if open
	
	Globals.singletons["Networking"].connect("spinreceived", self, "spin_data_received");
	Globals.singletons["Networking"].connect("closereceived", self, "close_round_received");
	Globals.singletons["Networking"].connect("fail", self, "error_received");
	
	JS.connect("spinstart", self, "start_spin");
	JS.connect("spindata", self, "spin_data_received");
	JS.connect("close", self, "close_round_received");	
	JS.connect("skip", self, "try_skip");	
	JS.connect("error", self, "error_received");
	
	timer.connect("timeout",self, "enter_idle");
	timer.set_one_shot(true);
	add_child(timer);
	
	Globals.singletons["Audio"].change_track("background", "MainTheme", 500, 1, 0.5);
	Globals.singletons["Audio"].loop("MainThemeMelody", 0);

	$IntroContainer/Centering/LogoMover/Logo.play_anim_then_loop("popup", "idle");
	$IntroContainer/ClickWaiter.enabled = true;
	Globals.singletons["Fader"].tween(1,0,0.5);

func enter_idle():
	Globals.singletons["Audio"].fade_to("MainThemeMelody", 0, 2000, 0);
	
func on_play_button_pressed():
	Globals.singletons["Audio"].play("Click");
	show_slot();
	
func show_slot():
	Globals.singletons["Stateful"].switch_to_state(Globals.singletons["Networking"].lastround.defaultTotal, true);
	Globals.update_win_configs(Globals.singletons["Networking"].lastround.defaultTotal);
	
	Globals.singletons["Fader"].tween(0.0,1.0,1.0);
	yield(Globals.singletons["Fader"], "done")
	
	var lastround = Globals.singletons["Networking"].lastround;
	update_spins_count(lastround);
	prints("FS:", freespins);

	if(freespins > 0): 
		prints("FREE SPINS", freespins)
		if("cumulativeWin" in lastround):
			Globals.singletons["WinBar"].show_win(lastround["cumulativeWin"], true);
		start_fs_instant();
#	else:
		#Globals.singletons["Audio"].change_music("MainTheme");
		
	if(freespins == 0):
		show_logo();
	
	$IntroContainer.queue_free();
	$SlotContainer.visible = true;
	$UIContainer.visible = true;
		
	Globals.singletons["Fader"].tween(1.0,0.0,0.5);
	yield(Globals.singletons["Fader"], "done");
	JS.output("", "elysiumgameshowui");

func _process(delta):
	pass
#	if(!JS.enabled && $SlotContainer.visible):		
#		if(Input.is_action_pressed("spin")): start_spin(null, false);
#		if(Input.is_action_pressed("spinforce")): start_spin(null, true);
#		if(Input.is_action_pressed("skip")):
#			if(Globals.canSpin): start_spin();
#			else: try_skip();

func start_spin(data=null, isforce = false):
	if(!Globals.canSpin): return;

	round_closed = false;
	round_ended = false;
	
	JS.output("", "elysiumgamespinstart");

	Globals.singletons["PopupTiles"].unpop_all();
	Globals.singletons["Audio"].fade_to("MainThemeMelody", 1, 500);
#	Globals.singletons["Audio"].fade("MainTheme", 0.5, 1, 1000);
	Globals.singletons["Audio"].fade_to_track("background", 1, 1000);
	
	if(Globals.singletons["WinLines"].shown):
		Globals.singletons["WinLines"].hide_lines();
		
	fs_ended = false;
	
	Globals.singletons["Slot"].start_spin();
	
	yield(Globals.singletons["Slot"], "onstartspin");
	
	if(Globals.singletons["WinBar"].shown && !in_freespins):
		Globals.singletons["WinBar"].hide();
		
	if(JS.enabled):
		pass
	else:
		if(isforce):
			#var force = funcref(Globals.singletons["Networking"], "force_freespin");
			#Globals.singletons["Networking"].request_force(force, 'filter:"freespin"');
	#	to force an InstaWin:
			var force = funcref(Globals.singletons["Networking"], "force_bonus");
			Globals.singletons["Networking"].request_force(force, 'filter:"InstaWin"');
		else:
			Globals.singletons["Networking"].request_spin();

func spin_data_received(data):
	if("code" in data || "hasError" in data): return;
	if(!Globals.singletons["Slot"].allspinning):
		yield(Globals.singletons["Slot"], "onstartspin");
	if(JS.enabled):
		Globals.singletons["Networking"].lastround = data;
		
	Globals.singletons["Networking"].update_state(data)
	
	#end_spin(data);
	
func end_spin(data):
	print("End spin");
	update_spins_count(data);
	Globals.singletons["Slot"].stop_spin(data);
		
	#Close it right away if we don't have any wins
	var wins = float(data["spinWin"]);
	if(wins == 0): close_round();
	
	yield(Globals.singletons["Slot"], "onstopped");
	timer.start(10);
#	Globals.singletons["Audio"].fade("MainThemeMelody", 1, 0, 2000, 0);
	Globals.singletons["Audio"].fade_to_track("background", 0.5, 2000);
	
	if(Globals.singletons["Nudger"].has_feature()):
		Globals.singletons["Nudger"].activate();
		yield(Globals.singletons["Nudger"], "activationend");
		yield(get_tree(), "idle_frame");
		
	if(Globals.singletons["BarsFillFx"].activate()):
		yield(Globals.singletons["BarsFillFx"], "animation_end");
		Globals.singletons["Stateful"].update_states();
		yield(get_tree().create_timer(0.5), "timeout");
	else:
		Globals.singletons["Stateful"].update_states();
	
	#Globals.singletons["Anticipation"].lighten_reels();
	var hasBonus = Globals.singletons["Bonus"].has_feature(data);
	#if(hasBonus || increase_fs || (!in_freespins && freespins > 0)):
	#	Globals.singletons["Audio"].play("Fight Win Shakuhachi");

	var has_line_wins := false;
	if(wins > 0):			
		if(Globals.singletons["PopupTiles"].remaining_tile_count > 0): 
			yield(Globals.singletons["PopupTiles"], "popuptilesend");
		Globals.singletons["PopupTiles"].clear_all();
		var line_wins = calculate_line_wins(data["wins"]);
		has_line_wins = line_wins > 0.0;
		
		if(has_line_wins):
			JS.output("linewin", "elysiumgamefeature");
			Globals.singletons["PopupTiles"].unpop_all();
			Globals.singletons["Audio"].play("WinLine")
			Globals.singletons["WinLines"].show_lines(data["wins"]);
			yield(Globals.singletons["WinLines"], "ShowEnd")
			if(line_wins >= Globals.singletons["BigWin"].big_win_limit):
				JS.output("bigwin", "elysiumgamefeature");
				Globals.singletons["BigWin"].show_win(line_wins);
				yield(Globals.singletons["BigWin"], "HideEnd")
				Globals.singletons["WinBar"].set_text(float(line_wins), false);
			elif(in_freespins):
				Globals.singletons["FsWinbar"].show_win(wins, false);
				yield(Globals.singletons["FsWinbar"], "CountEnd")
				if(!Globals.singletons["WinBar"].shown):
					Globals.singletons["WinBar"].set_text(float(line_wins));
				Globals.singletons["FsWinbar"].hide(true);
			else:
				Globals.singletons["WinBar"].show_win(line_wins, false);
				yield(Globals.singletons["WinBar"], "CountEnd")
				
		if(hasBonus):
			if(has_line_wins): 
				yield(get_tree().create_timer(1.0), "timeout");
				Globals.singletons["WinLines"].hide_lines();

			yield(get_tree().create_timer(1.0), "timeout");

			JS.output("bonus", "elysiumgamefeature");

			start_bonus(data);
			yield(Globals.singletons["Bonus"], "anim_end");
			#Globals.singletons["WinBar"].set_text(float(get_wins()), false);
			var bonus_wins = float(Globals.singletons["Bonus"].get_wins());
			if(in_freespins):
				Globals.singletons["BigWin"].show_win(bonus_wins, false);
			else:
				Globals.singletons["BigWin"].show_win(bonus_wins, true);
			yield(Globals.singletons["BigWin"], "HideEnd")
			if(!in_freespins):
				Globals.singletons["WinBar"].show_win(line_wins+bonus_wins, true);
			
		if(in_freespins):
			Globals.singletons["WinBar"].show_win(data["cumulativeWin"], true);
		elif (wins != Globals.singletons["WinBar"].target):
			Globals.singletons["WinBar"].show_win(wins, false);

	for feature in features:
		if(feature.has_feature(data)):
			feature.activate(data);
			yield(feature, "activationend");
			
	if(increase_fs):
		if(Globals.singletons["PopupTiles"].remaining_tile_count > 0): 
			yield(Globals.singletons["PopupTiles"], "popuptilesend");
		
		if(has_line_wins): 
			yield(get_tree().create_timer(1.0), "timeout");
			Globals.singletons["WinLines"].hide_lines();
			
		increase_fs = false;
		JS.output("freespinsinfreespins", "elysiumgamefeature");
		increase_fs();
		yield($SlotContainer/FreeSpinsIntro, "anim_end");
		$SlotContainer/Slot/FreeSpinsText/CounterText.text = str(freespins);
	
	if(!in_freespins && freespins > 0): 
		if(Globals.singletons["PopupTiles"].remaining_tile_count > 0): 
			yield(Globals.singletons["PopupTiles"], "popuptilesend");
		if(has_line_wins): 
			yield(get_tree().create_timer(1.0), "timeout");
			Globals.singletons["WinLines"].hide_lines();
		
		Globals.singletons["WinBar"].hide();
		JS.output("freespins", "elysiumgamefeature");
		start_fs();
		yield($SlotContainer/FreeSpinsIntro, "anim_end");
		$SlotContainer/Slot/FreeSpinsText/CounterText.text = str(freespins);
		
	if(in_freespins && freespins == 0):
		if(has_line_wins): 
			yield(get_tree().create_timer(1.0), "timeout");
			Globals.singletons["WinLines"].hide_lines();
			
		end_fs();
		if("cumulativeWin" in data && float(data["cumulativeWin"]) > 0.0):
			Globals.singletons["BigWin"].show_win(data["cumulativeWin"], true);
			Globals.singletons["WinBar"].hide();
			yield(Globals.singletons["BigWin"], "HideEnd")
			Globals.singletons["WinBar"].show_win(data["cumulativeWin"], true);
		
	if(!round_closed && freespins == 0):
		close_round();
		yield(self, "ready_to_close_round");
		
#	prints("FS COUNT: ",freespins);
	round_ended = true;
	
	JS.output("", "elysiumgameroundend");
	
func close_round(_data=null):
	if(freespins > 0): return;
	if(JS.enabled): JS.output("", "elysiumgameclose");
	else: Globals.singletons["Networking"].request_close();
	
func close_round_received(_data=null):
	round_closed = true;
	emit_signal("ready_to_close_round");

func update_spins_count(data):
	if(data.has("freeSpinsRemaining")):
		increase_fs = in_freespins && data["freeSpinsRemaining"] > freespins
		freespins = int(data["freeSpinsRemaining"]);

		#if(freespins == 0):
			#$SlotContainer/Slot/FreeSpinsText/CounterText.text = "";
		#elif(!increase_fs):
			#$SlotContainer/Slot/FreeSpinsText/CounterText.text = str(freespins);
	else: 
		freespins = 0;
		#$SlotContainer/Slot/FreeSpinsText.visible = false;

func calculate_line_wins(wins):
	if(wins == null): return 0.0;
	var n : float = 0.0;

	for win in wins: 
		if(win["index"].findn("freespin")>-1): continue;
		if(!win.has("winline")): n+=float(win["win"]); #winline 0
		elif(int(win["winline"]) > -1): n+=float(win["win"]);

	return n;	

func _input(ev):
#	if ev is InputEventKey and ev.scancode == KEY_F and not ev.echo:
#		if(!in_freespins): 
#			start_fs();
#
#	if ev is InputEventKey and ev.scancode == KEY_K and not ev.echo:
#		#increase_fs();
#		if(!Globals.singletons["Bonus"].shown):
#			Globals.singletons["Bonus"].activate(13, "Dark");
	pass
	
func start_fs_instant():
	$SlotContainer/AnimationPlayer.play("normal_to_fs");
	in_freespins = true;
	
func start_fs():
	in_freespins = true;
	Globals.singletons["WinLines"].hide_lines();
	$SlotContainer/FreeSpinsIntro.show();
	$SlotContainer/AnimationPlayer.play("normal_to_transparent");
	Globals.singletons["FaderBright"].tween(0.0,1.0,1);
	yield(get_tree().create_timer(1), "timeout");
	Globals.singletons["FaderBright"].tween(1.0,0.0,1);	
	yield($SlotContainer/FreeSpinsIntro, "anim_end");
	$SlotContainer/AnimationPlayer.play("normal_to_fs");
	Globals.singletons["FaderBright"].tween(0,0.6,1);
	yield(get_tree().create_timer(1.0), "timeout");
	Globals.singletons["FaderBright"].tween(0.6,0.0,1);
	yield(get_tree().create_timer(1), "timeout");
	
func increase_fs():
	$SlotContainer/FreeSpinsIntro.show_fast();	
	Globals.singletons["FaderBright"].tween(0.0,1.0,1);
	yield(get_tree().create_timer(1), "timeout");
	Globals.singletons["FaderBright"].tween(1.0,0.0,1);	
	yield($SlotContainer/FreeSpinsIntro, "anim_end");
	
func end_fs():
	$SlotContainer/AnimationPlayer.play("fs_to_normal");

	fs_ended = true;
	in_freespins = false;
#	Globals.singletons["Audio"].change_music("MainTheme");
	
func start_bonus(data):
	for feature in data["features"]:
		if(feature["type"] == "InstaWin"):
			Globals.singletons["Bonus"].activate(feature["data"]["amount"]);

	Globals.singletons["FaderBright"].tween(0.0,1.0,1);
	yield(get_tree().create_timer(1), "timeout")
	Globals.singletons["FaderBright"].tween(1.0,0.0,1);
	
func try_skip(data=null):
	Globals.emit_signal("skip");
	
func error_received(data):
	if(Globals.singletons["Slot"].spinning):
		if(!Globals.singletons["Slot"].allspinning):
			yield(Globals.singletons["Slot"], "onstartspin");
		Globals.singletons["Slot"].stop_spin();
		yield(Globals.singletons["Slot"], "onstopped");
	yield(get_tree(), "idle_frame");
	round_closed = true;
	round_ended = true;
	JS.output("", "elysiumgameroundend");
		
func show_logo():
	var logo = $SlotContainer/Slot/LogoMover/Logo;
	logo.set_timescale(1);
	logo.play_anim("popup", false);
	yield(logo, "animation_complete");
	logo.set_timescale(0.5);
	logo.play_anim("idle", true);
	
func update_state(state, init):
	var bar1 = 0.0;
	var bar2 = 0.0;
	
	if(state.has("counter1")):
		bar1 = float(state["counter1"])/float(state["max1"]);

	if(state.has("counter2")):
		bar2 = float(state["counter2"])/float(state["max2"]);
 
	if(init || !Globals.singletons["Bonus"].has_feature(Globals.singletons["Networking"].lastround)):
		if(bar1 >= 1.0 || bar2 >= 1.0): 
			bar1 = 0.0;
			bar2 = 0.0;
		
	Globals.singletons["BarGreen"].target_amount = bar1;
	Globals.singletons["BarBlue"].target_amount = bar2;

