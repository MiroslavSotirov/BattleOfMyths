extends Node2D
signal popup_end;

func show():
	#position.x = -540;
	$Character.play_anim("popup_appear", false);
	#yield($Character, "animation_complete");
	#yield(get_tree().create_timer(0.35), "timeout")
	yield($Character, "animation_complete");
	$AnimationPlayer.play("hide_character");
	yield($AnimationPlayer, "animation_finished");
	emit_signal("popup_end");
	queue_free();

