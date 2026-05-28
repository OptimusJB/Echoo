extends Button

func _on_pressed() -> void:
	# suppression de l'utilisateurs et ses playlists + images
	var noeud_database = get_tree().get_nodes_in_group("database")[0]
	var resultat = noeud_database.exec_sql("SELECT nom, id, image FROM Uplaylists WHERE id_utilisateur=?", [$"../../".id])
	if not resultat[0]:
		Notif.add_notif("échec de la récupérations des playlists de l'utilisateur")
		return
	
	# on supprime l'image de chaque playlist
	var dossier
	for playlist in resultat[1]:
		if not playlist["image"]:
			continue
		if FileAccess.file_exists(playlist["image"]):
			dossier = DirAccess.open(playlist["image"].get_base_dir())
			if not dossier:
				Notif.add_notif("échec de l'ouverture de l'image " + playlist["nom"])
			else:
				if dossier.remove(playlist["image"].get_file()) != OK:
					Notif.add_notif("échec de la suppression d'image de la playlist " + playlist["nom"])
				dossier = null	# pas sûr que ça serve mais en met quand même
				
	# on supprime les playlists et leurs référene dans Umusiques
	resultat = noeud_database.exec_sql("DELETE FROM UMusiques WHERE id_playlist IN (SELECT id FROM UPlaylists WHERE id_utilisateur=?)", [$"../../".id])
	if resultat[0]:
		resultat = noeud_database.exec_sql("DELETE FROM Uplaylists WHERE id_utilisateur=?", [$"../../".id])
	if not resultat[0]:
		Notif.add_notif("échec de la suppression des playlists de l'utilisateur")
		return
	
	# on supprime l'utilisateur
	resultat = noeud_database.exec_sql("DELETE FROM Utilisateurs WHERE id=?", [$"../../".id])
	if not resultat[0]:
		Notif.add_notif("échec de la suppression de l'utilisateur")
		return
	
	$"../../".queue_free()
	Notif.add_notif("utilisateur supprimé")
