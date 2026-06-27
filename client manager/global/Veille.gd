extends Node
# script augmentant le temps d'attente si la fenêtre n'est pas focus
var est_veille = false
var full_disable_veille = false

func mode_normal():
	get_tree().paused = false
	RenderingServer.render_loop_enabled = true	# ne sert pas trop
	OS.low_processor_usage_mode_sleep_usec = 6900
	#Engine.max_fps = 60
	est_veille = false
	
func mode_veille():
	get_tree().paused = true
	RenderingServer.render_loop_enabled = false	# ne sert pas trop
	OS.low_processor_usage_mode_sleep_usec = 6900*64#6900*32
	#OS.low_processor_usage_mode_sleep_usec = 6900*2
	#Engine.max_fps = 1
	est_veille = true
	
func _ready() -> void:
	#get_window().focus_entered.connect(mode_normal)
	#get_window().focus_exited.connect(mode_veille)
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if get_window().has_focus() or Client.nb_reponses_attendues > 0:
		if est_veille:
			mode_normal()
	elif not get_window().has_focus() and not full_disable_veille:
		if not est_veille:
			mode_veille()
	#print(est_veille)
