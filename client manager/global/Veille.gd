extends Node
# script augmentant le temps d'attente si la fenêtre n'est pas focus

func mode_normal():
	OS.low_processor_usage_mode_sleep_usec = 6900
	#Engine.max_fps = 60
	pass
	
func mode_veille():
	OS.low_processor_usage_mode_sleep_usec = 6900*64#6900*32
	#Engine.max_fps = 1
	
	
func _ready() -> void:
	get_window().focus_entered.connect(mode_normal)
	get_window().focus_exited.connect(mode_veille)
