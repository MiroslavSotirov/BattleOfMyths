extends Node2D;

const IMAGE_MARGIN = 80;
enum Position {LEFT = 1, RIGHT = -1};

func _ready():
	$firstTxt/SpriteLangSwap.connect(
		"asset_swapped",
		 self, 
		"_set_position", 
		[$firstTxt, Position.LEFT]
	);
	
	$secondTxt/SpriteLangSwap.connect(
		"asset_swapped", 
		self, 
		"_set_position", 
		[$secondTxt, Position.RIGHT]
	);
	

func _set_position(el, positionSign):
	el.position.x = $BonusBeatsSign.position.x - positionSign * (el.texture.get_width() / 2 - IMAGE_MARGIN);

