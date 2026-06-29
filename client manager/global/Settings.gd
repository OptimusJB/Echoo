extends Node

var save_filename="settings.txt"
var settings = {}

var presets = {"server_manager":{"echelle":1.0, "mode bannissement":0, "taille envoi fichier":5.0, "liste blanche ip":[]},
"client":{"echelle":1.0, "ip":"", "port":25565, "type connexion":"wss", "charger images":1, "cache max":100, "type son":0, "qualite":"max", "volume":1.0, "generer mipmaps":1, "commencer à la chanson cliquee":0, "langue":"", "telechargements":{"musiques":{}, "images":{}, "images id":{}, "next image id":0, "est commun":1}}}
var use_json = false

func save_settings(use_debug=false) -> int:
	# sauvegarde
	var fichier = FileAccess.open("user://" + save_filename, FileAccess.WRITE)
	if not fichier:
		push_error("erreur lors de l'ouverture du fichier")
		return 0
	
	if use_json:
		fichier.store_string(JSON.stringify(settings))
		#print(JSON.stringify(settings))
	else:
		fichier.store_var(settings)
	fichier.close()
	
	if use_debug:	# uniquement utile si enregistrement pas en json
		# on fait un deuxième fichier en json
		use_json = true
		var old_save_filename=save_filename
		save_filename = save_filename.get_basename() + "_debug.json"
		save_settings(false)
		save_filename = old_save_filename
		use_json = false
	return 1

func load_settings(preset:String = "null") -> int:
	# chargement
	# preset sert si le fichier n'est pas trouvé
	var success=false
	if FileAccess.file_exists("user://" + save_filename):
		var fichier = FileAccess.open("user://" + save_filename, FileAccess.READ)
		if not fichier:
			push_error("erreur lors de l'ouverture du fichier")
		
		if not use_json :
			settings = fichier.get_var()
			success = true
		else:
			var json = JSON.parse_string(fichier.get_as_text())
			#print("json : ", json, ", type : ", type_string(typeof(json)))
			#print("type valeur : ", type_string(typeof(json["echelle"])))
			#print(1.0 == 1)
			if json:
				success = true
				settings = json
		fichier.close()
		# note : les int deviennent des float
	
	if not success:
		# échec de récupération de la save, donc on prend un preset
		if preset != "null":
			if not preset in presets.keys():
				push_error("le preset " + preset + " n'existe pas")
				return 0
			settings = presets[preset].duplicate()
	return 1
	
func set_setting(cle:String, valeur, auto_save=true) -> void:
	settings[cle] = valeur
	if auto_save:
		save_settings()

func get_setting(cle, valeur_base=null):
	# si pas de valeur, assigne et retourne valeur_base
	if not cle in settings.keys():
		set_setting(cle, valeur_base, false)
	return settings[cle]
