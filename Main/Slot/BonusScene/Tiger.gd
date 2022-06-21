extends Node2D

signal show_end;

func show():
	$Character.position = Vector2(0, 0)
	$Character.play_anim("popup_appear", false);
	yield(get_tree().create_timer(1.0), "timeout");
	$AnimationPlayer.play("hide_character");
	yield($AnimationPlayer, "animation_finished");
	emit_signal("show_end");
		
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
	$AnimationPlayer.play("hide_effect");
	yield($AnimationPlayer, "animation_finished");	
	queue_free();

