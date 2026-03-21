extends Control
var noeud_appelant

func auto_position():
	# posision de la liste
	var options_size = $"fond".size
	var screen_size = size
	var mouse_position = get_local_mouse_position()
	$"fond".position = mouse_position
	if mouse_position[0] + options_size[0] > screen_size[0]:
		# dépassement droit
		$"fond".position.x = screen_size[0] - options_size[0]
	if mouse_position[1] + options_size[1] > screen_size[1]:
		# dépassement bas
		$"liste options".position.y = screen_size[1] - options_size[1]
	
	$fond.size = Vector2.ZERO	# si on change la position, le size à ce moment llà semble devenir le size de base
	
func creer_sous_menu(ce_noeud, liste_options:Array):
	# fonction qui fait spawn le sous-menu
	# ce_noeud = noeud ayant appelé la fonction
	if len(liste_options) == 0:
		push_error("liste_options est vide")
		return
	
	noeud_appelant = ce_noeud
	
	for enfant in $"fond/liste options".get_children():
		enfant.free()
	
	#$"fond/liste options".size = Vector2.ZERO
	#$"fond".size = Vector2.ZERO
	var new_bouton
	for option in liste_options:
		new_bouton = $"bouton type".duplicate()
		new_bouton.text = option
		new_bouton.visible = true
		$"fond/liste options".add_child(new_bouton)
		
		# on connecte son signal
		new_bouton.option_choisie.connect(option_finale)
	
	auto_position()
	visible=true

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			visible=false

func option_finale(option:String):
	# on cache le sous menu et on appelle la fonction de sortie du noeud appelant
	visible = false
	noeud_appelant.action(option)
