extends Control

export (Vector2) var zoomamount : Vector2;
export (Vector2) var yoffset : Vector2;

func _ready():
	Globals.connect("resolutionchanged", self, "on_resolution_changed");
	
func on_resolution_changed(landscape, portrait, screenratio, zoom):
	var zoomratio = lerp(1, 0.2, clamp(inverse_lerp(0.0, 1, screenratio), 0, 1));
	rect_scale = Vector2.ONE * lerp(zoomamount.x, zoomamount.y, zoomratio);
	#rect_scale = Vector2.ONE * zoomratio;
	rect_pivot_offset = rect_size/2;
	zoomratio = clamp(1.0-zoomratio, 0.0, 1.0);
	var vertical_offset = clamp(inverse_lerp(0.5, 1.0, zoomratio),0.0,1.0);
	vertical_offset = lerp(yoffset.x, yoffset.y, vertical_offset);

	#var zoomoffset = max(0, rect_pivot_offset.y) - max(0, Globals.resolution.y);
	#vertical_offset -= 35;
	set_global_position(vertical_offset * Vector2.UP)
