extends Popup

func _ready():
	pass

func _process(delta):
	pass
	
func set_text(string):
	$Label.text = string;
	
func hide():
	self.visible = false;

func _on_Button_pressed():
	hide();
