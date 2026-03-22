extends HBoxContainer

var file_select
var qualite_ajout:String

signal charger_album

func ajouter_musiques(qualite:String):
	assert(qualite in ["min", "moy", "max"], "qualite invalide")
	qualite_ajout = qualite
	file_select.popup_file_dialog()
	
func get_nom_musique(chemin_fichier:String):
	var troncature = FonctionsGlobal.to_int($"troncature".text)
	chemin_fichier = chemin_fichier.get_file()
	chemin_fichier = chemin_fichier.substr(min(troncature, len(chemin_fichier))) # pas vraiment besoin du min mais on met quand même
	
	# on enlève l'extension
	chemin_fichier = chemin_fichier.get_basename()
	
	return chemin_fichier
	
	
func fichiers_choisis(chemins_fichiers):
	var resultat
	var noeud_database = get_tree().get_nodes_in_group("database")[0]
	var nom_musique
	# les deux variables suivantes sont utilisées pour les notifs
	var modif = false
	var ajout = false
	
	var max_position_album
	var id_album = FonctionsGlobal.to_int($"../album actuel/id album".text)
	
	# on charge max_position_album
	resultat = noeud_database.exec_sql("SELECT MAX(position_album) AS max_pos FROM Musiques WHERE id_album=?", [id_album])
	if not resultat[0]:
		Notif.add_notif("échec de l'ajout des musiques")
		return
		
	max_position_album = FonctionsGlobal.to_int(resultat[1][0]["max_pos"])
	
	# on trie les musiques
	chemins_fichiers.sort()
	for chemin_fichier in chemins_fichiers:
		nom_musique = get_nom_musique(chemin_fichier)
		# on regarde si une musique s'appelle déjà comme ça
		# si oui on remplace, sinon nouvelle musique
		resultat = noeud_database.exec_sql("SELECT * FROM Musiques WHERE nom=? AND id_album=?", [nom_musique, id_album])
		if not resultat[0]:
			Notif.add_notif("échec de la récupération des musiques")
			continue

		if len(resultat[1]) > 0:
			# on change une musique déjà existante
			# note : ça modifie toutes les musiques ayant le nom (même si ça n'a aucun sens de mettre plusieurs musiques du même nom)
			resultat = noeud_database.exec_sql("UPDATE Musiques SET " + str(qualite_ajout) + "=? WHERE id_album=? AND nom=?", [chemin_fichier, id_album, nom_musique])
			if not resultat[0]:
				Notif.add_notif("échec de l'ajout de la musique : " + str(nom_musique))
				continue
			modif = true
		else:
			resultat = noeud_database.exec_sql("INSERT INTO Musiques(nom, id_album, position_album, " + str(qualite_ajout) + ") VALUES(?, ?, ?, ?)", [nom_musique, id_album, max_position_album + 1, chemin_fichier])
			max_position_album += 1
			ajout = true
		
	# notif de succès
	if modif and ajout:
		Notif.add_notif("musiques ajoutées et modifiées")
	elif modif:
		Notif.add_notif("musiques modifiées")
	elif ajout:
		Notif.add_notif("musiques ajoutées")
	else:
		Notif.add_notif("pas de modifications")
	# on recharge toutes les musiques
	charger_album.emit(id_album)
	
func _on_min_pressed() -> void:
	ajouter_musiques("min")
	
func _on_moy_pressed() -> void:
	ajouter_musiques("moy")

func _on_max_pressed() -> void:
	ajouter_musiques("max")

func _ready() -> void:
	# on crée le filedialog
	await get_tree().process_frame
	file_select = FileDialog.new()
	file_select.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	file_select.access = FileDialog.ACCESS_FILESYSTEM
	file_select.add_filter("*.ogg", "musiques ogg")
	file_select.add_filter("*.mp3", "musiques mp3")
	file_select.add_filter("*.wav", "musiques wav")
	get_tree().get_nodes_in_group("windows")[1].add_child(file_select)
	file_select.files_selected.connect(fichiers_choisis)
