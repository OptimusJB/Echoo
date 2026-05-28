extends Button


signal charger_artiste

func _on_pressed() -> void:
	var id_artiste = get_node("../../LineEdit").id_artiste
	charger_artiste.emit(id_artiste)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and not event.is_pressed():
			# on appelle le sous-menu
			var sousmenu = get_tree().get_nodes_in_group("SousMenu")[0]
			sousmenu.creer_sous_menu(self, ["ouvrir la page de l'artiste", "modifier l'image", "supprimer l'artiste"])

func action(type_action:String):
	# sortie du sous-menu
	var id_artiste = get_node("../../LineEdit").id_artiste
	if type_action == "supprimer l'artiste":
		# on supprime l'artiste
		var database = get_tree().get_nodes_in_group("database")[0]
		
		# on tente de d'abord supprimer les albums et musiques liées à cet album
		# globalement DELETE FROM se fout totalement des foreign keys, bizarre vu que sur db_browser ça bloque
		var resultat = database.exec_sql("DELETE FROM UMusiques WHERE id_musique IN (SELECT id FROM Musiques WHERE id_album IN (SELECT id FROM Albums WHERE id_artiste = ?))", [id_artiste])
		if resultat[0]:
			resultat = database.exec_sql("DELETE FROM Musiques WHERE id_album IN (SELECT id FROM Albums WHERE id_artiste = ?)", [id_artiste])
		if resultat[0]:
			resultat = database.exec_sql("DELETE FROM Albums WHERE id_artiste = ?", [id_artiste])
		if resultat[0]:
			resultat = database.exec_sql("DELETE FROM Artistes WHERE id=?",  [id_artiste])
		if not resultat[0]:
			Notif.add_notif("échec de la suppression de l'artiste")
			return
		Notif.add_notif("artiste supprimé")
		
		# on enlève l'artiste actuel si c'est le même et que c'est ouvert
		if int(get_tree().get_nodes_in_group("artiste actuel")[0].get_node("id artiste").text) == id_artiste and get_tree().get_nodes_in_group("parties")[1].get_node("../").visible:
			get_tree().get_nodes_in_group("parties")[1].get_node("../").visible = false
			# on cache également la vue de l'album actuel
			get_tree().get_nodes_in_group("parties")[2].visible = false
		
		$"../../".queue_free()
		
	elif type_action == "ouvrir la page de l'artiste":
		charger_artiste.emit(id_artiste)
	
	elif type_action == "modifier l'image":
		var file_dialog = get_tree().get_nodes_in_group("file dialogs")[0]
		file_dialog.noeud_appelant = self
		file_dialog.popup_file_dialog()
	
func fichier_choisi(chemin_fichier):
	# on change l'image de l'artiste (pas de vérification)
	var id_artiste = get_node("../../LineEdit").id_artiste
	var database = get_tree().get_nodes_in_group("database")[0]
	var resultat = database.exec_sql("UPDATE Artistes SET image=? WHERE id=?", [chemin_fichier, id_artiste])
	if not resultat[0]:
		Notif.add_notif("échec du changement d'image")
		return
		
	# on change l'image de l'artiste et l'artiste actuel s'il est ouvert
	var texture = RessourceLoad.easy_get_image(chemin_fichier)
	$"../image".texture = texture
	if int(get_tree().get_nodes_in_group("artiste actuel")[0].get_node("id artiste").text) == id_artiste and get_tree().get_nodes_in_group("parties")[1].get_node("../").visible:
		get_tree().get_nodes_in_group("artiste actuel")[0].get_node("image artiste").texture = texture
