extends Object
class_name TileData

var id = 1;
var feature;
var variant;

func _init(id = 1, feature = null):
	self.id = id;
	self.feature = feature;
	self.variant = -1;
