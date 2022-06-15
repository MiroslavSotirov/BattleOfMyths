extends Node

var current_music : String = "";
var sfx_times = {};

func _ready():
	Globals.register_singleton("Audio", self);

func play(sfx, vol=1.0):
	JS.play_sound(sfx, vol);
	
func play_after(sfx, delay, vol=1.0):
	JS.play_sound_after(sfx, delay, vol);

func play_time_rate(sfx, vol=1.0, mintime=100):
	if(sfx_times.has(sfx)):
		if(sfx_times[sfx] > OS.get_ticks_msec()): 
			return
			
	JS.play_sound(sfx, vol);
	sfx_times[sfx] = OS.get_ticks_msec()+mintime;

func stop(sfx):
	JS.stop_sound(sfx);

func loop(sfx, vol=1.0):
	JS.loop_sound(sfx, vol);
	
func pause(sfx):
	JS.pause_sound(sfx);

#func volume(sfx, level):
#	JS.volume(sfx, level);

func fade(sfx, from, to, duration, stopOnZero=1):
	JS.fade_sound(sfx, from, to, duration, stopOnZero);

func fade_to(sfx, to, duration, stopOnZero=1):
	JS.fade_sound_to(sfx, to, duration, stopOnZero);

func fade_track(track, from, to, duration, stopOnZero=1):
	JS.fade_track(track, from, to, duration, stopOnZero);

func fade_to_track(track, to, duration, stopOnZero=1):
	JS.fade_to_track(track, to, duration, stopOnZero);
	
func change_track(track, sound, transition, loop=0, level=1, stop_previous=1):
	JS.change_track(track, sound, transition, loop, level, stop_previous);

func change_music(new_track):
	if(new_track == current_music): return;
	if(current_music != ""):
		fade(current_music, 1, 0, 1);
	loop(new_track);
	fade(new_track, 0, 1, 1);
	current_music = new_track;
	
