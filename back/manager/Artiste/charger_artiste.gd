extends Button
signal charger_artiste

func _on_pressed() -> void:
	var id_artiste = get_node("../../LineEdit").id_artiste
	charger_artiste.emit(id_artiste)

func _gui_input(event: InputEvent) -> void:
	if event.is_action_type():
		if event.button_index == MOUSE_BUTTON_RIGHT and not event.is_pressed():
			# on appelle le sous-menu
			var sousmenu = get_tree().get_nodes_in_group("SousMenu")[0]
			sousmenu.creer_sous_menu(self, ["ouvrir la page de l'artiste", "supprimer l'artiste"])

func action(type_action:String):
	# sortie du sous-menu
	print("action choisie : " + type_action)
