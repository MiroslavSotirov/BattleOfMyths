extends Node2D

func show_on(fat_tile):
	var x = (fat_tile.x * 2 + fat_tile.w);
	var positions = x if x <= 6 else 6 - (x - 6);
	var direction = 1 if x <= 6 else -1;
	$Character.position = Vector2(direction * positions * 108, 0)
	$Character.play_anim("popup_appear", false);
	$Character.scale.x = direction;
	yield($Character, "animation_complete");
	$AnimationPlayer.play("hide_character");
	
func hit(pos, size = 2):
#	203 x 182
	var scale = size / 2.0;
	print("the tiles_count ", size)
	print("the scalet ", scale)
	$TilesEffect.scale.x = scale;
	$TilesEffect.scale.y = scale;
	# 274 x 235
	var w = 160 * ((size - 1) * 0.5)
	var h = 182 * ((size - 1) * 0.5 )
	$TilesEffect.position = Vector2(pos.x + w,  pos.y + h);
	$TilesEffect.visible = true;
#	$Character.play_anim("popup", false);
#	yield($Character, "animation_complete");

	$TilesEffect.play_anim("popup_appear", false);
	yield($TilesEffect, "animation_complete");

func hide():
	$TilesEffect.play_anim("closemouth", false);
#	yield($TilesEffect, "animation_complete");
	
	$AnimationPlayer.play("hide_effect");
	yield($AnimationPlayer, "animation_finished");
	queue_free();

