extends Node
var noeud_musique = load("res://client/scènes/Musique/Musique.tscn")
var script_get_ressource = load("res://client/scènes/Accueil/easy_get_ressource.gd").new()

# variables globales
var pseudo = ""
var mdp = ""

var taille_envoi_fichier = 0.0
var id_serveur = 0

var id_current_download = null	# id de la musique atuellement en train d'être téléchargée (utile pour les musiques affichées)

var start_music_selected = null # pour le shift sélection des musiques
#var musics_selected = [] # liste des musiques sélectionnées

func to_int(texte):
	# retourne l'élément en int, 0 si problème
	if texte is int:
		return texte
	if not texte:
		return 0
	if texte is float:
		return int(round(texte))
	if texte is String and texte.is_valid_int():
		return int(texte)
	return 0

func to_float(texte):
	# retourne l'élément en float, 0.0 si problème
	if texte is float:
		return texte
	if not texte:
		return 0.0
	if texte is String and texte.is_valid_float() or texte is int:
		return float(texte)
	return 0.0

func to_text(element):
	# retourne l'element en str, et "" si null
	if not element:
		return ""
	return str(element)

func to_text_int(element):
	# retourne l'élément sous forme d'entier en str
	# ex : 'truc' -> '0'
	#      '2025' -> '2025'
	return str(to_int(element))

func to_text_float(element):
	return str(to_float(element))

func secondes_to_text(temps:int):
	var minutes = int(float(temps)/60)
	var secondes = (temps % 60)
	return str(minutes) + ":" + str(secondes).pad_zeros(2)

func text_to_secondes(texte:String):
	var parties = texte.split(":")
	return int(parties[0]) * 60 + int(parties[1])

func est_musique_telecharge(id_musique:int, qualite:String):
	# setting telechargements de la forme {"musiques":{"id":{min":extension, "moy":extension, "max":extension}}}, "images":{nom:{"extension", "nb utilisations"}}
	assert(qualite in ["min", "moy", "max"], "qualité invalide")
	return id_musique in Settings.get_setting("telechargements")["musiques"].keys() and Settings.get_setting("telechargements")["musiques"][id_musique] != null

func est_musique_existante(id_musique:int):
	# renvoie true si l'id de la musique est enregistrée
	return id_musique in Settings.get_setting("telechargements")["musiques"].keys()

func est_image_telecharge(id_album:int):
	return id_album in Settings.get_setting("telechargements")["images"].keys()

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
	
	new_noeud.get_node("éléments/masque/image").texture = await script_get_ressource.easy_get_image(image)
	new_noeud.album_clicked.connect(get_tree().get_first_node_in_group("enumeration")._album_clicked)
	new_noeud.artiste_clicked.connect(get_tree().get_first_node_in_group("enumeration")._artiste_clicked)
	
	return new_noeud

func create_folders() -> int:
	# fonction qui crée les dossiers de stockage des musiques et des images s'ils n'existent pas
	if not DirAccess.dir_exists_absolute("user://downloaded/"):
		if DirAccess.make_dir_absolute("user://downloaded/") != OK:
			return 0
	return 1
		
func telecharger_musiques(liste_id_musiques):
	# WARNING la fonction de vérifie pas si le client est bloqué
	# on récupère la qualité
	var noeud_player = get_tree().get_first_node_in_group("player")
	var qualite = Settings.get_setting("qualite")
	
	var data_musique
	var data_image
	var new_musique
	var new_image
	for id_musique in liste_id_musiques:
		id_current_download = id_musique
		await get_tree().process_frame
		
		# on vérifie d'abord si l'id de la musique est téléchargé
		if not est_musique_telecharge(id_musique, qualite):
			# on télécharge la musique
			data_musique = await script_get_ressource.easy_get_music(id_musique, qualite, true)
			if data_musique is String and data_musique == "no quality":
				continue
			
			# on enregistre la musique
			if not est_musique_existante(id_musique):
				#Settings.get_setting("telechargements")["musiques"][id_musique] = {"min":null, "moy":null, "max":null}
				new_musique = {"min":null, "moy":null, "max":null}
			else:
				new_musique = Settings.get_setting("telechargements")["musiques"][id_musique]
			new_musique[qualite] = data_musique[0]
			
			if not create_folders():
				push_error("impossible de créer les dossiers d'enregistrements")
				Notif.add_notif("DOWNLOAD_FAILED")
				id_current_download = null
				return
				
			var nom_fichier = str(id_musique) + qualite + ".music"
			var fichier = FileAccess.open("user://downloaded/" + nom_fichier, FileAccess.WRITE)
			if not fichier or not fichier.store_buffer(data_musique[1]):
				push_error("échec de l'écriture de la musique")
				Notif.add_notif("DOWNLOAD_FAILED")
				id_current_download = null
				return
			fichier.close()
			Settings.get_setting("telechargements")["musiques"][id_musique] = new_musique
			
			# on récupère l'image si option activée
			if Settings.get_setting("charger images"):
				var id_image:int
				# on détermine l'id de l'image si elle existe déjà, sinon on lui en attribue une
				# id images de la forme {"nom image":id_associé}
				if noeud_player.infos_musiques[id_musique]["image"] in Settings.get_setting("telechargements")["images id"].keys():
					id_image = Settings.get_setting("telechargements")["images id"][noeud_player.infos_musiques[id_musique]["image"]]
				else:
					id_image = Settings.get_setting("telechargements")["next image id"]
					#Settings.get_setting("telechargements")["images id"][noeud_player.infos_musiques[id_musique]["image"]] = id_image
					#Settings.set_setting("next image id", id_image + 1, false)
					
				if est_image_telecharge(id_image):
					Settings.get_setting("telechargements")["images"][id_image]["nb utilisations"] += 1
				else:
					data_image = await script_get_ressource.easy_get_image_buffer(noeud_player.infos_musiques[id_musique]["image"])
					if data_image != null:
						# on enregistre l'image
						new_image = {"extension":null, "nb utilisations":0}
						#Settings.get_setting("telechargements")["images"][noeud_player.infos_musiques[id_musique]["image"]] = {"extension":null, "nb utilisations":0}
						new_image["extension"] = data_image[0]
						
						# on écrit dans le fichier
						nom_fichier = str(id_image) + ".image"
						fichier = FileAccess.open("user://downloaded/" + nom_fichier, FileAccess.WRITE)
						if not fichier or not fichier.store_buffer(data_image[1]):
							push_error("échec de l'écriture de l'image")
							Notif.add_notif("DOWNLOAD_FAILED")
							id_current_download = null
							return
						fichier.close()
						
						Settings.get_setting("telechargements")["images"][id_image] = new_image
						
						# on enregistre dans les settings l'id associé (car ajout de la musique réussie)
						Settings.get_setting("telechargements")["images id"][noeud_player.infos_musiques[id_musique]["image"]] = id_image
						Settings.get_setting("telechargements")["next image id"] = id_image + 1
			Settings.save_settings()
	id_current_download = null
