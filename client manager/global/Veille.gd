extends Node
# script augmentant le temps d'attente si la fenêtre n'est pas focus

var disable_veille = false

func mode_normal():
	OS.low_processor_usage_mode_sleep_usec = 6900
	#Engine.max_fps = 60
	pass
	
func mode_veille():
	if disable_veille:
		return
	OS.low_processor_usage_mode_sleep_usec = 6900*64#6900*32
	#OS.low_processor_usage_mode_sleep_usec = 6900*2
	#Engine.max_fps = 1
	
func _ready() -> void:
	get_window().focus_entered.connect(mode_normal)
	get_window().focus_exited.connect(mode_veille)

func _process(_delta: float) -> void:
	var noeud_enumeration = get_tree().get_first_node_in_group("enumeration")
	if noeud_enumeration and noeud_enumeration.get_child_count() > 0:
		if noeud_enumeration.get_child(0) is settings_view:
			disable_veille = true	# pour les select
			return
	disable_veille = false
