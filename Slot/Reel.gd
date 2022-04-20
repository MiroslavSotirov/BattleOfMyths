# State: Show Wins
extends VFSMStateBase


func enter() -> void:	
#	if(Globals.singletons["PopupTiles"].remaining_tile_count > 0): 
#		yield(Globals.singletons["PopupTiles"], "popuptilesend");
#	Globals.singletons["PopupTiles"].clear_all();
#
#	var data = Globals.singletons["Networking"].lastround;
#	var line_wins = calculate_line_wins(data["wins"]);
#	data["wins_lines_total"] = line_wins;
#
#	JS.output("linewin", "elysiumgamefeature");
#	Globals.singletons["PopupTiles"].unpop_all();
#	Globals.singletons["Audio"].play("WinLine")
#	Globals.singletons["WinLines"].show_lines(data["wins"]);
#
#	yield(Globals.singletons["WinLines"], "ShowEnd")
#
#	if(line_wins > Globals.singletons["BigWin"].big_win_limit):
#		JS.output("bigwin", "elysiumgamefeature");
#		Globals.singletons["BigWin"].show_win(line_wins);
#		yield(Globals.singletons["BigWin"], "HideEnd")
#		Globals.singletons["WinBar"].set_text(line_wins, false);
#		Globals.fsm_data["big_win_shown"] = true;
#	else:
#		Globals.singletons["WinBar"].set_text(float(line_wins), false);
	
	Globals.fsm_data["wins_shown"] = true;
	
func calculate_line_wins(wins):
	if(wins == null): return 0.0;
	var n : float = 0.0;

	for win in wins: 
		if(win["index"].findn("freespin")>-1): continue;
		if(!win.has("winline")): n+=float(win["win"]); #winline 0
		elif(int(win["winline"]) > -1): n+=float(win["win"]);

	return n;	

func update(_object, _delta: float) -> void:
	pass


func exit() -> void:
	pass
