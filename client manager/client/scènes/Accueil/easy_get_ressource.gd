extends Node
var noeud_musique = load("res://client/scènes/Musique/Musique.tscn")
signal image_received
signal music_received

# ATTENTION les fonctions ne vérifient pas Client.is_locked
func easy_get_image_buffer(chemin_image):
	# fonction qui récupère l'image via le serveur
	# on importe l'image
	if not chemin_image:
		return null
	Client.noeud_appelant = self
	Client.send(JSON.stringify({"type":"get image", "image":chemin_image}))
	var reponse = await image_received
	
	return [chemin_image.get_extension(), reponse[1]]
	
func easy_get_music(id_musique, qualite, return_buffer=false):
	var reponse = [null, null]
	var extension
	var telechargement_success = false
	
	# on regarde d'abord si la musique est téléchargée
	if est_musique_telecharge(id_musique, qualite):
		# on tente de réupérer la musique
		var qualite_dl = qualite
		if Settings.get_setting("telechargements")["est commun"]:
			# peut importe la qualité de la musique, elle sera considérée comme téléchargée
			qualite_dl = "commun"
		
		var nom_fichier = str(id_musique) + qualite_dl + ".music"
		var fichier = FileAccess.open("user://downloaded/" + nom_fichier, FileAccess.READ)
		if not fichier:
			push_error("échec du chargement de la musique")
			Notif.add_notif("GET_MUSIC_DOWNLOAD_FAILED")
		else:	
			reponse = [null, fichier.get_buffer(fichier.get_length())]
			if not reponse[1]:
				push_error("échec du chargement de la musique")
				Notif.add_notif("GET_MUSIC_DOWNLOAD_FAILED")
				fichier.close()
				#id_current_download = null
			else:
				telechargement_success = true
				extension = Settings.get_setting("telechargements")["musiques"][id_musique][qualite_dl]
				print("utilisation de musique téléchargée : ", extension)
				fichier.close()
	
	if not telechargement_success:
		# on demande la musique au serveur
		Client.noeud_appelant = self
		Client.send(JSON.stringify({"type":"get music", "id":id_musique, "qualite":qualite}))
		reponse = await music_received
		
		# on vérifie qu'une qualité est disponible
		if reponse[0]["qualite"] == "non":
			Notif.add_notif("NO_QUALITY")
			return "no quality"
		
		extension = reponse[0]["resultat"]	# avec le '.' devant
	
		# on renvoie le résultat si return_buffer==true
		if return_buffer:
			return [extension, reponse[1]]
		
	# on charge la musique
	#print("octets reçus : ", len(reponse[1]))
	var musique_stream
	if extension == ".mp3":
		musique_stream = AudioStreamMP3.load_from_buffer(reponse[1])
	elif extension == ".ogg":
		musique_stream = AudioStreamOggVorbis.load_from_buffer(reponse[1])
	elif extension == ".wav":
		musique_stream = AudioStreamWAV.load_from_buffer(reponse[1])
	else:
		return null
	if not musique_stream:	# load_from_buffer renvoie null si échoué
		return null
	
	if not telechargement_success and reponse[0]["qualite"] != qualite:
		Notif.add_notif(tr("QUALITY_NOT_AVAILABLE") % [qualite, reponse[0]["qualite"]])
	return musique_stream
	
func easy_get_image(chemin_image):
	if not chemin_image:
		RessourceLoad.set_icone_base(chemin_image)
		return RessourceLoad.icone_base

	# on regarde si l'image est chargée
	var image
	if RessourceLoad.is_loaded(chemin_image):
		image = RessourceLoad.get_ressource(chemin_image)
		if not image:
			RessourceLoad.set_icone_base(chemin_image)
			image = RessourceLoad.icone_base
	elif not Settings.get_setting("charger images"):
		RessourceLoad.set_icone_base(chemin_image)
		image = RessourceLoad.icone_base
	else:
		var telechargement_success = false
		var reponse = [null, null]
		var musique_telecharge = false
		
		# on regarde si l'image est téléchargée
		if chemin_image in Settings.get_setting("telechargements")["images id"].keys():
			var id_image = Settings.get_setting("telechargements")["images id"][chemin_image]
			if est_image_telecharge(id_image):
				musique_telecharge = true
				var nom_fichier = str(id_image) + ".image"
				var fichier = FileAccess.open("user://downloaded/" + nom_fichier, FileAccess.READ)
				if not fichier:
					push_error("échec du chargement de l'image")
					RessourceLoad.set_icone_base(chemin_image)
					image = RessourceLoad.icone_base
				else:	
					reponse = [null, fichier.get_buffer(fichier.get_length())]
					if not reponse[1]:
						push_error("échec du chargement de l'image")
						fichier.close()
						RessourceLoad.set_icone_base(chemin_image)
						image = RessourceLoad.icone_base
						#id_current_download = null
					else:
						telechargement_success = true
						print("utilisation d'image téléchargée")
						fichier.close()
		
		if not musique_telecharge:	# on ne tente pas de récupérer l'image fail d'ouverture du fichier
			# on importe l'image
			Client.noeud_appelant = self
			Client.send(JSON.stringify({"type":"get image", "image":chemin_image}))
			reponse = await image_received
		
		if not (musique_telecharge and not telechargement_success):
			# on charge l'image
			RessourceLoad.charger_ressource(chemin_image, reponse[1], Settings.get_setting("cache max"))
			image = RessourceLoad.get_ressource(chemin_image)
			if not image:
				RessourceLoad.set_icone_base(chemin_image)
				image = RessourceLoad.icone_base
	return image

func received(message_json, message_bytes):
	
	if not Client.check_keys(message_json, ["type", "resultat"]):
		push_error("clés invalides")
		Client.socket.close()
		return
	if message_json["type"] == "get image":
		image_received.emit(message_json, message_bytes)
	else:
		if not Client.check_keys(message_json, ["qualite"]):
			push_error("clés invalides")
			Client.socket.close()
			return
		music_received.emit(message_json, message_bytes)

# téléchargements
func est_musique_telecharge(id_musique:int, qualite:String):
	# setting telechargements de la forme {"musiques":{"id":{min":extension, "moy":extension, "max":extension, "id image":id}}}, "images":{"extension", "nb utilisations"}, "images id":{"nom":"id"}, "next image id":entier, "est commun":entier bool}
	assert(qualite in ["min", "moy", "max", "commun"], "qualité invalide")
	if Settings.get_setting("telechargements")["est commun"]:
		# peut importe la qualité de la musique, elle sera considérée comme téléchargée
		qualite = "commun"
	return id_musique in Settings.get_setting("telechargements")["musiques"].keys() and Settings.get_setting("telechargements")["musiques"][id_musique] != null
	
func est_musique_existante(id_musique:int):
	# renvoie true si l'id de la musique est enregistrée
	return id_musique in Settings.get_setting("telechargements")["musiques"].keys()

func est_image_telecharge(id_image:int):
	return id_image in Settings.get_setting("telechargements")["images"].keys() and Settings.get_setting("telechargements")["images"][id_image]["extension"] != null

func est_image_presente(id_image:int):
	return id_image in Settings.get_setting("telechargements")["images"].keys()
	
func create_folders() -> int:
	# fonction qui crée les dossiers de stockage des musiques et des images s'ils n'existent pas
	if not DirAccess.dir_exists_absolute("user://downloaded/"):
		if DirAccess.make_dir_absolute("user://downloaded/") != OK:
			return 0
	return 1
		
func telecharger_musiques(liste_id_musiques):
	# WARNING la fonction de vérifie pas si le client est bloqué
	# on récupère la qualité
	var noeud_player = Client.get_tree().get_first_node_in_group("player")
	var qualite_import = Settings.get_setting("qualite")	# qualité demandé à easy_get_music
	var qualite = qualite_import	# qualité de stockage (égal à qualite_import ou "commun")
	
	if Settings.get_setting("telechargements")["est commun"]:
		# peut importe la qualité de la musique, elle sera considérée comme téléchargée
		qualite = "commun"
	
	var data_musique
	var data_image
	var new_musique
	var new_image
	for id_musique in liste_id_musiques:
		FonctionsGlobal.id_current_download = id_musique
		await Client.get_tree().process_frame
		
		# on vérifie d'abord si l'id de la musique est téléchargé
		if not est_musique_telecharge(id_musique, qualite):
			# on télécharge la musique
			data_musique = await easy_get_music(id_musique, qualite_import, true)
			if data_musique is String and data_musique == "no quality":
				continue
			
			# on enregistre la musique
			if not est_musique_existante(id_musique):
				#Settings.get_setting("telechargements")["musiques"][id_musique] = {"min":null, "moy":null, "max":null}
				new_musique = {"min":null, "moy":null, "max":null, "commun":null, "id image":null}	# on met l'id de l'image pour garder une cohérene avec nb utilisations (au cas où ça a changé sur le serveur)
			else:
				new_musique = Settings.get_setting("telechargements")["musiques"][id_musique].duplicate()
				
			new_musique[qualite] = data_musique[0]
			
			if not create_folders():
				push_error("impossible de créer les dossiers d'enregistrements")
				Notif.add_notif("DOWNLOAD_FAILED")
				FonctionsGlobal.id_current_download = null
				return
				
			var nom_fichier = str(id_musique) + qualite + ".music"
			var fichier = FileAccess.open("user://downloaded/" + nom_fichier, FileAccess.WRITE)
			if not fichier:
				push_error("échec de l'écriture de la musique")
				Notif.add_notif("DOWNLOAD_FAILED")
				continue

			if not fichier.store_buffer(data_musique[1]):
				push_error("échec de l'écriture de la musique")
				Notif.add_notif("DOWNLOAD_FAILED")
				fichier.close()
				#id_current_download = null
				continue	# pas gênant pour les autres musiques, donc on continue
			fichier.close()
			
			# on récupère les infos de l'image (on le met même si charger images n'est pas activé)
			var id_image:int
			# on détermine l'id de l'image si elle existe déjà, sinon on lui en attribue une
			# id images de la forme {"nom image":id_associé}
			if noeud_player.infos_musiques[id_musique]["image"] in Settings.get_setting("telechargements")["images id"].keys():
				id_image = Settings.get_setting("telechargements")["images id"][noeud_player.infos_musiques[id_musique]["image"]]
			else:
				id_image = Settings.get_setting("telechargements")["next image id"]
				# on enregistre dans les settings l'id associé
				Settings.get_setting("telechargements")["images id"][noeud_player.infos_musiques[id_musique]["image"]] = id_image
				Settings.get_setting("telechargements")["next image id"] = id_image + 1
			
			# on met id image de la musique sur la musique
			new_musique["id image"] = id_image
			Settings.get_setting("telechargements")["musiques"][id_musique] = new_musique
			
			# on augmente le compteur d'utilisations de l'image
			if est_image_presente(id_image):
				Settings.get_setting("telechargements")["images"][id_image]["nb utilisations"] += 1
			else:
				Settings.get_setting("telechargements")["images"][id_image] = {"extension":null, "nb utilisations":1}
			Settings.save_settings()
			
			if Settings.get_setting("charger images"):
				if not est_image_telecharge(id_image):
					data_image = await easy_get_image_buffer(noeud_player.infos_musiques[id_musique]["image"])
					if data_image != null:
						# on enregistre l'image
						new_image = {"extension":null, "nb utilisations":Settings.get_setting("telechargements")["images"][id_image]["nb utilisations"]}
						#Settings.get_setting("telechargements")["images"][noeud_player.infos_musiques[id_musique]["image"]] = {"extension":null, "nb utilisations":0}
						new_image["extension"] = data_image[0]
						
						# on écrit dans le fichier
						nom_fichier = str(id_image) + ".image"
						fichier = FileAccess.open("user://downloaded/" + nom_fichier, FileAccess.WRITE)
						if not fichier:
							push_error("échec de l'écriture de l'image")
							Notif.add_notif("DOWNLOAD_FAILED")
							continue
							
						if not fichier.store_buffer(data_image[1]):
							push_error("échec de l'écriture de l'image")
							Notif.add_notif("DOWNLOAD_FAILED")
							fichier.close()
							#id_current_download = null
							# il ne faut pas sauvegarder sinon nb utilisation sera incohérent
							continue	# ce n'est pas gênant pour les suivants, donc on continue
						fichier.close()
						
						Settings.get_setting("telechargements")["images"][id_image] = new_image
						Settings.save_settings()
	FonctionsGlobal.id_current_download = null

func supprimer_musiques(liste_id_musiques):
	# WARNING la fonction de vérifie pas si le client est bloqué
	var noeud_player = Client.get_tree().get_first_node_in_group("player")
	var qualite = Settings.get_setting("qualite")	# qualité demandé à easy_get_music
		
	if Settings.get_setting("telechargements")["est commun"]:
		# peut importe la qualité de la musique, elle sera considérée comme téléchargée
		qualite = "commun"
	
	# on tente de supprimer chaque musique
	for id_musique in liste_id_musiques:
		# on regarde d'abord si la musique est enregistrée
		if not est_musique_telecharge(id_musique, qualite):
			continue
		# on regarde si la musique existe dans le dossier
		var nom_fichier = str(id_musique) + qualite + ".music"
		if FileAccess.file_exists("user://downloaded/" + nom_fichier):
			# on supprime le fichier
			if DirAccess.remove_absolute("user://downloaded/" + nom_fichier) != OK:
				push_error("échec de la suppression du fichier audio")
				Notif.add_notif("DOWNLOAD_FAILED")
				continue
		else:
			push_warning("le fichier %s n'existe pas, on suppose qu'il a été supprimé" % nom_fichier)
		
		# on met à null la qualité
		Settings.get_setting("telechargements")["musiques"][id_musique][qualite] = null
		
		#var id_image = Settings.get_setting("telechargements")["images id"][noeud_player.infos_musiques[id_musique]["image"]]
		var id_image = Settings.get_setting("telechargements")["musiques"][id_musique]["id image"]
		# on enlève une utilisation
		Settings.get_setting("telechargements")["images"][id_image]["nb utilisations"] -= 1
		
		# on supprime la référence si toutes les qualités sont à null
		for qualite_test in ["min", "moy", "max", "commun"]:
			if Settings.get_setting("telechargements")["musiques"][id_musique][qualite_test] != null:
				break
			if qualite_test == "commun":
				Settings.get_setting("telechargements")["musiques"].erase(id_musique)
		Settings.save_settings()
		
	# nettoyage des images, on les supprime du disque et on enlève leur référence si elles ne sont plus utilisées
	# on regarde même celles non liées à la boucle précédente, au cas la suppression avait raté précédemment
	for chemin_image in Settings.get_setting("telechargements")["images id"].keys().duplicate():
		var id_image = Settings.get_setting("telechargements")["images id"][chemin_image]
		if Settings.get_setting("telechargements")["images"][id_image]["nb utilisations"] < 0:
			print("utilisations : ", Settings.get_setting("telechargements")["images"][id_image]["nb utilisations"])
			push_error("une image a un nombre d'utilisations négatives")
		elif Settings.get_setting("telechargements")["images"][id_image]["nb utilisations"] == 0:
			# on tente de supprimer l'image
			var nom_fichier = str(id_image) + ".image"
			if FileAccess.file_exists("user://downloaded/" + nom_fichier):
				# on supprime le fichier
				if DirAccess.remove_absolute("user://downloaded/" + nom_fichier) != OK:
					push_error("échec de la suppression de l'image")
					Notif.add_notif("DOWNLOAD_FAILED")
					continue
			else:
				push_warning("le fichier %s n'existe pas, on suppose qu'il a été supprimé" % nom_fichier)
				
			# on supprime les références à cette image
			Settings.get_setting("telechargements")["images"].erase(id_image)
			Settings.get_setting("telechargements")["images id"].erase(chemin_image)
			Settings.save_settings()

# création musique
func creer_musique(id:int, position_playlist:int, nom:String, id_artiste:int, nom_artiste:String, id_album:int, nom_album:String, image:String, afficher_numero:bool) -> Node:
	var new_noeud = noeud_musique.instantiate()
	
	# on check si la musique est téléchargée
	if est_musique_telecharge(id, Settings.get_setting("qualite")):
		new_noeud.est_telecharge = true
		new_noeud.get_node("éléments/milieu/HBoxContainer/downloaded").visible = true
		
	if not afficher_numero:	# on ne l'affiche pas pour éviter de créer un espace bizarre
		new_noeud.get_node("éléments/gauche/numéro").visible = false
	new_noeud.afficher_numero = afficher_numero
	new_noeud.id = id
	new_noeud.id_album = id_album
	new_noeud.id_artiste = id_artiste
	new_noeud.position_playlist = position_playlist
	
	new_noeud.get_node("éléments/gauche/numéro").text = FonctionsGlobal.to_text(position_playlist + 1)
	new_noeud.get_node("éléments/milieu/HBoxContainer/titre").text = nom
	new_noeud.get_node("éléments/milieu/artiste").text = nom_artiste
	new_noeud.get_node("éléments/album").text = nom_album
	
	new_noeud.get_node("éléments/masque/image").texture = await easy_get_image(image)
	new_noeud.album_clicked.connect(Client.get_tree().get_first_node_in_group("enumeration")._album_clicked)
	new_noeud.artiste_clicked.connect(Client.get_tree().get_first_node_in_group("enumeration")._artiste_clicked)
	
	return new_noeud
