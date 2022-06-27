extends Control;

export(Resource) var spine_data;

var SpineSprite = load("res://Main/SpineSpriteExtension.gd");
var targetpos = 0.0;

func _ready():
	Globals.register_singleton("Explosions", self);

func show_at(data, reels):
	var explosionPromises = [];
	for index in data.keys():
		var reel = reels[index];
		for i in data[index]:
			var position = reel.get_tile_global_position(i);
			explosionPromises.append(_add_explosion(position));

	return Promise.all(explosionPromises);

func _add_explosion(position):
	_explosion_fx(position);	
	var fx = load("res://Main/Slot/BonusScene/MultFx.tscn").instance();
	var target = Globals.singletons["WinMultiplier"];
	Globals.singletons["Slot"].add_child(fx);
	fx.speed += randf() * 0.1;
	var startoffset = Vector2((randf()*30.0)-15.0, (randf()*30.0)-15.0)
	fx.global_position = position + startoffset;
	fx.set_points(fx, target);
	fx.offsets[0] = startoffset;
	fx.offsets[2] = Vector2(0, 50.0) + Vector2((randf()*30.0)-15.0, (randf()*30.0)-15.0);
	yield(fx, "move_complete");

func _explosion_fx(position):
	var explotion = SpineSprite.new();
	explotion.scale.x = 0.4 + randf() * 0.2;
	explotion.scale.y = 0.4 + randf() * 0.2;
	explotion.rotation = randf() * TAU;
	explotion.set_new_state_data(spine_data);
	self.add_child(explotion);
	explotion.global_position = position;
	explotion.play_anim('explore', false);
	
	yield(explotion, "animation_complete");
	self.remove_child(explotion);
