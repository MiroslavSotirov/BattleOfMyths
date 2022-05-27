extends Control

func _ready():
	Globals.register_singleton("UI", self);
	Globals.connect("resolutionchanged", self, "on_resolution_changed");

func on_resolution_changed(landscape, portrait, screenratio, zoom):
	$LandscapeUI.visible = landscape;
	$PortraitUI.visible = portrait;

func show_error(text):
	$ErrorPopup.set_text(text);
	$ErrorPopup.popup_centered_ratio();

