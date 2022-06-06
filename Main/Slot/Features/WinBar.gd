extends Control

var shown = false;
var tween : Tween;
var amount : float;
var target : float;
var bangup_factor : float = 1;

signal CountEnd
signal HideEnd;

func _ready():
	VisualServer.canvas_item_set_z_index(get_canvas_item(), 19);
	amount = 0.0;
	Globals.register_singleton(name, self);
	
func show_win(target, bottom = true):
	if(float(target) == self.amount):
		set_text(target, false)
		yield(get_tree(), "idle_frame");
		return emit_signal("CountEnd");
		
	self.target = target;

	if(!shown):
		if(bottom): $AnimationPlayer.play("ShowBottom");
		else: $AnimationPlayer.play("Show");
		
	$CounterText.text = Globals.format_money(amount);
	
	tween = Tween.new();
	add_child(tween);
	
	var duration;
#	for some odd reason when the target and the amount are equal, the equality comparison
#   returns falseand target - amount is equal to -0,
#   so they are first changed to strings and then compared
	if(bottom || String(self.target) == String(self.amount)):
		duration = 0;
	else:
		duration = min(3.5, self.target / self.bangup_factor);

	tween.interpolate_method(self, "set_text", 
		amount, self.target, duration, 
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT);
		
	tween.start();
	tween.connect("tween_all_completed", self, "count_end");
	$AnimationPlayer.seek($AnimationPlayer.current_animation_length, true);
	shown = true;
	
	if(duration != 0): Globals.singletons["Audio"].loop("CoinsEndless")
	
func set_text(v, instantshow=true):
	if(!shown):
		$AnimationPlayer.play("ShowBottom");
		if(instantshow): $AnimationPlayer.seek($AnimationPlayer.current_animation_length, true);
		shown = true;
	amount = float(v);
	$CounterText.text = Globals.format_money(v);

func count_end():
	Globals.singletons["Audio"].stop("CoinsEndless")
	if($AnimationPlayer.assigned_animation == "Show"):
		$AnimationPlayer.play("GoDown");
		yield($AnimationPlayer,"animation_finished")
	emit_signal("CountEnd");

func hide(instant=false):
	if(!shown): return;
	if(tween != null && is_instance_valid(tween)):
		tween.queue_free();
		tween = null;
		set_text(target);
		Globals.singletons["Audio"].stop("CoinsEndless")
	shown = false;
	if(instant):
		$AnimationPlayer.play("Hide");
		$AnimationPlayer.seek($AnimationPlayer.current_animation_length,true);
	else:
		$AnimationPlayer.play("Hide");
		yield($AnimationPlayer, "animation_finished");
	amount = 0.0;
	emit_signal("HideEnd");
