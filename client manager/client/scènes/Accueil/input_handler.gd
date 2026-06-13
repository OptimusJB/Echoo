extends Control
# script qui s'occupe des raccourcis claviers

func _input(event: InputEvent) -> void:
	# on vérifie d'abord que le focus n'est pas un champs de texte
	var focus_actuel = get_window().gui_get_focus_owner()
	if focus_actuel is LineEdit or focus_actuel is TextEdit:
		return
	
	# on vérifie que ctrl n'est pas pressé (si pressé, cela veut dire qu'on veut changer la résolution / clear le cache)
	if Input.is_key_pressed(KEY_CTRL):
		return
		
	var noeud_player = get_tree().get_first_node_in_group("player")
	if noeud_player.get_node("../").visible:
		if event.is_action_released("play"):
			# on switch l'état du bouton play
			noeud_player.get_node("centre/boutons/size jouer/jouer").button_pressed = not noeud_player.get_node("centre/boutons/size jouer/jouer").button_pressed
		elif event.is_action_released("suivant"):
			noeud_player._on_suivant_pressed()
		elif event.is_action_released("précédent"):
			noeud_player._on_precedent_pressed()
		elif event.is_action_released("répéter"):
			# on switch l'état du bouton repeter
			noeud_player.get_node("centre/boutons/size repeter/repeter")._on_pressed()
		elif event.is_action_released("random"):
			# on switch l'état du bouton aléatoire
			noeud_player.get_node("centre/boutons/size aléatoire/aléatoire").button_pressed = not noeud_player.get_node("centre/boutons/size aléatoire/aléatoire").button_pressed
		elif event.is_action_released("file d'attente"):
			# on switch l'état du bouton file d'attente
			noeud_player.get_node("droite/size file d'attente/file d'attente").button_pressed = not noeud_player.get_node("droite/size file d'attente/file d'attente").button_pressed
