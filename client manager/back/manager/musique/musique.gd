extends HBoxContainer
var id:int

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and not event.is_pressed():
			# on appelle le sous-menu
			var sousmenu = get_tree().get_nodes_in_group("SousMenu")[0]
			sousmenu.creer_sous_menu(self, ["déplacer la sélection ici", "supprimer la sélection"])

func action(type_action:String):
	# sortie du sous-menu
	var resultat
	var noeud_database = get_tree().get_nodes_in_group("database")[0]
	
	if type_action == "supprimer la sélection":
		# on supprime tous les éléments sélectionnés
		var noeud_liste_musiques = get_tree().get_nodes_in_group("liste musiques")[0]
		var position_musique = 1
		
		for musique in noeud_liste_musiques.get_children():
			if musique.get_node("select").button_pressed:
				# on supprime la musique et ses références dans Uplaylists
				resultat = noeud_database.exec_sql("DELETE FROM UMusiques WHERE id_musique=?", [musique.id])
				if resultat[0]:
					resultat = noeud_database.exec_sql("DELETE FROM Musiques WHERE id=?", [musique.id])
				if not resultat[0]:
					Notif.add_notif("échec partielle de la suppression")
					musique.get_node("position").text = str(position_musique)
					position_musique = position_musique + 1
				else:
					musique.queue_free()
			else:
				musique.get_node("position").text = str(position_musique)
				position_musique = position_musique + 1
				
	elif type_action == "déplacer la sélection ici":
		var old_musique = null
		
		# on on déplace tous les éléments
		var noeud_liste_musiques = get_tree().get_nodes_in_group("liste musiques")[0]
		for musique in noeud_liste_musiques.get_children():
			if musique.get_node("select").button_pressed:
				if not musique == self:
					noeud_liste_musiques.move_child(musique, 0)
					if not old_musique:
						noeud_liste_musiques.move_child(musique, get_index() - 1)
					else:
						noeud_liste_musiques.move_child(musique, old_musique.get_index())
				old_musique = musique	# indenter d'un cran supplémentaire pour créer feature
					
		# on fait un parcours et on change la position via requête pour chaque musique
		for musique in noeud_liste_musiques.get_children():
			resultat = noeud_database.exec_sql("UPDATE Musiques SET position_album = ? WHERE id = ?", [musique.get_index(), musique.id])
			if not resultat[0]:
				Notif.add_notif("échec partiel de changement de position")
				continue	# on met un continue comme ça on peut voir vite fait où est le problème
			musique.get_node("position").text = FonctionsGlobal.to_text(musique.get_index() + 1)
