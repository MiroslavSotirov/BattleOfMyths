extends Node

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_MOUSE_ENTER:
		pass;
	elif what == MainLoop.NOTIFICATION_WM_MOUSE_EXIT:
		pass;
		
	if what == MainLoop.NOTIFICATION_WM_FOCUS_IN:
		print("Focused")
		get_tree().paused = false;
	elif what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
		print("Out of focus")
		get_tree().paused = true;
