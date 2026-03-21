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
	var id_musique = id
	if type_action == "supprimer l'album":
		# on supprime l'artiste
		var database = get_tree().get_nodes_in_group("database")[0]
		"""
		# on tente de d'abord supprimer les musiques liées à cet album
		# note : les Uplaylists ne sont pas vérifiées (pas impactées par la contrainte de clé étrangère), il est préférable de tester s'il existe quand l'utilisateur demande à charger la playlist
		# globalement DELETE FROM se fout totalement des foreign keys, bizarre vu que sur db_browser ça bloque
		var resultat = database.exec_sql("DELETE FROM Musiques WHERE id_album = ?", [id_album])
		if resultat[0]:
			resultat = database.exec_sql("DELETE FROM Albums WHERE id=?",  [id_album])
		if not resultat[0]:
			Notif.add_notif("échec de la suppression de l'album")
			return
		Notif.add_notif("album supprimé")
		
		# on enlève l'album actuel si c'est le même et que c'est ouvert
		if int(get_tree().get_nodes_in_group("album actuel")[0].get_node("id album").text) == id_album and get_tree().get_nodes_in_group("parties")[2].visible:
			get_tree().get_nodes_in_group("parties")[2].visible = false
		
		# on supprime l'album
		$"../../".queue_free()
	"""
	elif type_action == "modifier l'image":
		#file_select.popup_file_dialog()
		pass
