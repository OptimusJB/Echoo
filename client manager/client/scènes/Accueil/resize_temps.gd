extends Label
@export var noeud_label_voisin:Control
var old=0
func check_taille():
	#print("check")
	var taille_actuel = $"../temps actuel".get_minimum_size().x
	var taille_max = $"../temps max".get_minimum_size().x
	var taille = max(taille_actuel, taille_max)
	#print("taille : ", taille)
	noeud_label_voisin.custom_minimum_size.x = taille
	custom_minimum_size.x = taille
	
func _process(delta: float) -> void:
	check_taille()
	#print(Engine.get_process_frames())
	
	set_process(false)
	for i in range(30):
		await get_tree().process_frame
	set_process(true)
