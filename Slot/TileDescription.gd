extends Resource
class_name TileDescription

export(int) var id := 0;
export(int) var size_x := 1;
export(int) var size_y := 1;
export(Resource) var spine_data;
export(bool) var popup := false;
export(bool) var popup_z_change := false;
export(bool) var popup_wait := false;
export(String) var image_creation_animation := "popup";
export(String) var spine_popup_anim := "";
export(float) var spine_popup_anim_speed := 1.0;
export(String) var popup_sfx := "";
export(String) var spine_idle_anim := "";
export(String) var spine_win_anim := "";
export(int) var spine_win_anim_animation_repeat := -1;
export(Vector2) var image_offset : Vector2;
export(Vector2) var image_size : Vector2 = Vector2(100.0,100.0);
export(Vector2) var tile_offset : Vector2;
export(Vector2) var tile_scale : Vector2 = Vector2.ONE;
export(Array) var posible_reels := [];
export(int) var max_count := 0;

var static_image : ImageTexture;
