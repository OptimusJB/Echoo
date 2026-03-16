extends Node

var save_filename="settings.txt"
var settings = {}

var presets = {"server_manager":{"echelle":1.0}}

func save_settings() -> int:
	# sauvegarde
	var fichier = FileAccess.open("user://" + save_filename, FileAccess.WRITE)
	if not fichier:
		push_error("erreur lors de l'ouverture du fichier")
		return 0
	
	fichier.store_var(settings)
	fichier.close()
	return 1

func load_settings(preset:String = "null") -> int:
	# chargement
	# preset sert si le fichier n'est pas trouvé
	var success=false
	if FileAccess.file_exists("user://" + save_filename):
		var fichier = FileAccess.open("user://" + save_filename, FileAccess.READ)
		if not fichier:
			push_error("erreur lors de l'ouverture du fichier")
	
		settings = fichier.get_var()
		fichier.close()
		success = true
	
	if not success:
		# échec de récupération de la save, donc on prend un preset
		if preset != "null":
			if not preset in presets.keys():
				push_error("le preset " + preset + " n'existe pas")
				return 0
			settings = presets[preset]
	return 1
	
func set_setting(cle:String, valeur, auto_save=true) -> void:
	settings[cle] = valeur
	if auto_save:
		save_settings()

func get_setting(cle, valeur_base=null):
	# si pas de valeur, assigne et retourne valeur_base
	if not cle in settings.keys():
		set_setting(cle, valeur_base)
	return settings[cle]
