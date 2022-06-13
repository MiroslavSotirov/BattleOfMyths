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
