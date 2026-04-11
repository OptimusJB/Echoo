extends Button
var utilisateur = load("res://back/manager/Utilisateur/Utilisateur.tscn")
var chargement_utilisateurs = false

func _on_pressed() -> void:
	if chargement_utilisateurs:
		return
	chargement_utilisateurs = true
	
	var type_recherche = $"../type recherche".selected
	# on fait une verif du selected au cas où
	if type_recherche == -1:
		return
	
	var recherche = $"../chercher pseudo".text
	var noeud_liste_utilisateurs = get_tree().get_nodes_in_group("liste utilisateurs")[0]
	var noeud_database = get_tree().get_nodes_in_group("database")[0]
	
	# on met la partie_sql qu'il faut selon le type de recherche
	var sql_recherche = ""
	if type_recherche == 0:
		# tous
		sql_recherche = ""
	elif type_recherche == 1:
		# non bannis
		sql_recherche = " AND banni = 0"
	elif type_recherche == 2:
		# bannis
		sql_recherche = " AND banni = 1"
	else:
		push_error("type_recherche invalide")
		# sql_recherche déjà à "" de base
		
	# requête sql
	var resultat = noeud_database.exec_sql("SELECT * FROM Utilisateurs WHERE username LIKE ?" + sql_recherche, ["%" + recherche + "%"])
	if not resultat[0]:
		Notif.add_notif("échec de la récupération des utilisateurs")
		chargement_utilisateurs = false
		return
	
	# on supprime tous les potentiels noeuds déjà présents
	for element in noeud_liste_utilisateurs.get_children():
		element.queue_free()
		
	# on charge la liste des utilisateurs
	var new_utilisateur
	for utilisateur_actuel in resultat[1]:
		await get_tree().process_frame
		new_utilisateur = utilisateur.instantiate()
		new_utilisateur.get_node("HBoxContainer/VBoxContainer/pseudo").text = FonctionsGlobal.to_text(utilisateur_actuel["username"])
		new_utilisateur.get_node("HBoxContainer/VBoxContainer/ip").text = "ip : " + FonctionsGlobal.to_text(utilisateur_actuel["ip"])
		new_utilisateur.id = FonctionsGlobal.to_int(utilisateur_actuel["id"])
		
		# on change le fond s'il est banni
		if utilisateur_actuel["banni"]:
			new_utilisateur.set_banni()
		
		# on l'ajoute
		noeud_liste_utilisateurs.add_child(new_utilisateur)
		
	chargement_utilisateurs = false
