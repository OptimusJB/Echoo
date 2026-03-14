extends Node
var loaded = {}	# de la forme chemin_ressource:ressource
var icone_base = load("res://assets/icone_base.png")

func get_ressource_extension(chemin_ressource:String) -> String:
	return chemin_ressource.split(".")[len(chemin_ressource.split("."))-1]

func is_loaded(chemin_ressource):
	return chemin_ressource in loaded.keys()
	
func get_ressource(chemin_ressource):
	if not is_loaded(chemin_ressource):
		return 0
	return loaded[chemin_ressource]
	
func charger_ressource(chemin_ressource, data:PackedByteArray):
	# la fonction réécrit dans loaded, même si ça existe déjà
	var ressource
	var erreur = 0
	var extension = get_ressource_extension(chemin_ressource)
	
	# on check si c'est null
	if not chemin_ressource:
		set_icone_base(chemin_ressource)
		return
		
	if extension == "png":
		ressource = Image.new()
		erreur = ressource.load_png_from_buffer(data)
		ressource = ImageTexture.create_from_image(ressource)
	elif extension == "jpg" or extension == "jpeg":
		ressource = Image.new()
		erreur = ressource.load_jpg_from_buffer(data)
		ressource = ImageTexture.create_from_image(ressource)
	elif extension == "bmp":
		ressource = Image.new()
		erreur = ressource.load_bmp_from_buffer(data)
		ressource = ImageTexture.create_from_image(ressource)
	elif extension == "svg":
		ressource = Image.new()
		erreur = ressource.load_svg_from_buffer(data)
		ressource = ImageTexture.create_from_image(ressource)
	else:
		erreur = 1 # tout sauf 0
		
	if erreur != OK:
		Notif.add_notif("échec du chargement de la ressource de chemin " + str(chemin_ressource))
		loaded[chemin_ressource] = icone_base
	else:
		loaded[chemin_ressource] = ressource

func set_icone_base(chemin_ressource):
	loaded[chemin_ressource] = icone_base
	
func get_file_data(chemin_fichier):
	# renvoie un contenu vide si erreur, et base si vide
	if not chemin_fichier:	# chemin fichier vide
		return "base".to_utf8_buffer()
	if not FileAccess.file_exists(chemin_fichier):
		push_error("le fichier %s n'existe pas" % chemin_fichier)
		return "".to_utf8_buffer()
	return FileAccess.get_file_as_bytes(chemin_fichier)
