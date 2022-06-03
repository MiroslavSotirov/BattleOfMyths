tool
extends Node
func _get_tool_buttons(): return ["export_all_pck"]

func _ready():
	var do_export = false;
	for argument in OS.get_cmdline_args():
		if(argument == "-export_pck"): 
			do_export = true;
			break;
			
	if(do_export): export_all_pck(true);

func export_all_pck(quit=false):
	print("EXPORTING PCK...")
	var children = get_children();
	for child in children:
		child.export_pck();
		#yield(child, "export_completed")
	
	print("COMPLETED")
	if(quit):
		OS.kill(OS.get_process_id())
