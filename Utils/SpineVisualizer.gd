tool
extends SpineSpriteExtension
class_name SpineDebugVisualizer

func _get_tool_buttons(): return ["play_current_anim"]

func _ready():
	if(Engine.editor_hint): return;
	._ready();

func play_current_anim():
	._ready();
