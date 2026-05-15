extends Node
var loaded = {}	# de la forme chemin_ressource:ressource
var load_history = []
var icone_base = load("res://assets/icone_base.png")
var dossier_images_utilisateurs = "users playlists images/"	# contient les images des playlists des utilisateurs

func clear():
	# supprime tout le contenu de loaded
	loaded.clear()
	load_history = []
	
func get_ressource_extension(chemin_ressource:String) -> String:
	return chemin_ressource.split(".")[len(chemin_ressource.split("."))-1]

func is_loaded(chemin_ressource):
	return chemin_ressource in loaded.keys()
	
func get_ressource(chemin_ressource):
	if not is_loaded(chemin_ressource):
		return 0
	return loaded[chemin_ressource]
	
func charger_ressource(chemin_ressource, data, cache_max=-1):
	# la fonction réécrit dans loaded, même si ça existe déjà
	var ressource
	var erreur = 0
	var extension = get_ressource_extension(chemin_ressource)
	var generer_mipmaps = FonctionsGlobal.to_int(Settings.get_setting("generer mipmaps"))
	
	# on check si c'est null
	if not chemin_ressource or not data:
		set_icone_base(chemin_ressource)
		return
		
	if extension == "png":
		ressource = Image.new()
		erreur = ressource.load_png_from_buffer(data)
		if generer_mipmaps:
			ressource.generate_mipmaps()
		ressource = ImageTexture.create_from_image(ressource)
	elif extension == "jpg" or extension == "jpeg":
		ressource = Image.new()
		erreur = ressource.load_jpg_from_buffer(data)
		if generer_mipmaps:
			ressource.generate_mipmaps()
		ressource = ImageTexture.create_from_image(ressource)
	elif extension == "bmp":
		ressource = Image.new()
		erreur = ressource.load_bmp_from_buffer(data)
		if generer_mipmaps:
			ressource.generate_mipmaps()
		ressource = ImageTexture.create_from_image(ressource)
	elif extension == "svg":
		ressource = Image.new()
		erreur = ressource.load_svg_from_buffer(data)
		if generer_mipmaps:
			ressource.generate_mipmaps()
		ressource = ImageTexture.create_from_image(ressource)
	else:
		erreur = 1 # tout sauf 0
		
	if erreur != OK:
		loaded[chemin_ressource] = icone_base
	else:
		loaded[chemin_ressource] = ressource
		load_history.append(chemin_ressource)
		
		while cache_max > 0 && len(load_history) > cache_max:
			# on supprime le contenu
			print("suppression de " + load_history[0] + " du cache")
			if load_history[0] in loaded.keys():
				loaded.erase(load_history[0])
			load_history.remove_at(0)
	return erreur

func set_icone_base(chemin_ressource):
	# ne compte pas dans l'historique
	loaded[chemin_ressource] = icone_base
	
func get_file_data(chemin_fichier):
	# renvoie un contenu vide si erreur, et base si vide
	if not chemin_fichier:	# chemin fichier vide
		return "base".to_utf8_buffer()
	if not FileAccess.file_exists(chemin_fichier):
		push_error("le fichier %s n'existe pas" % chemin_fichier)
		return "".to_utf8_buffer()
	return FileAccess.get_file_as_bytes(chemin_fichier)

func easy_get_image(chemin_image):
	# fonction qui utilise les fonctions au dessus pour charger et retourner une image depuis le disque
	# null peut être une clé
	var image_bytes
	
	# on change le null en "" (même si normalement ça marche avec le null)
	if not chemin_image:
		chemin_image = ""
	
	if not is_loaded(chemin_image):
		# on check si c'est une image de base
		if not chemin_image:
			set_icone_base(chemin_image)
		else:
			image_bytes = get_file_data(chemin_image)
			if image_bytes == "".to_utf8_buffer():
				Notif.add_notif("échec du chargement du fichier " + chemin_image)
				set_icone_base(chemin_image)
			else:
				if charger_ressource(chemin_image, image_bytes) != OK:	# notif automatique
					Notif.add_notif("échec de la conversion de la ressource de chemin " + str(chemin_image))
			if not (get_ressource(chemin_image) is ImageTexture or get_ressource(chemin_image) is Texture2D):	# Texture2D pour l'icône de base
				set_icone_base(chemin_image)
				push_error("la ressource d'id %d n'est pas une image" % chemin_image)
				Notif.add_notif("la ressource d'id %d n'est pas une image" % chemin_image)
	return get_ressource(chemin_image)

func is_image_in_folder(nom_image:String, chemin_dossier=null):
	# le dossier doit se terminer par un slash
	# le nom image ne doit pas avoir d'extension
	# ATTENTION fonction pas testée
	if not chemin_dossier:
		chemin_dossier = dossier_images_utilisateurs
	assert(chemin_dossier[len(chemin_dossier) - 1] == "/", "chemin_dossier doit se terminer par un /")
	var liste_extensions = [".png", ".jpg", ".jpeg", ".bmp", ".svg"]
	for extension in liste_extensions:
		if FileAccess.file_exists(chemin_dossier + nom_image + extension):
			return true
	return false
