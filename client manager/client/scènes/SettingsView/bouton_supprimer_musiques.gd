extends Button

var script_get_ressource = null

signal maj_dl_numbers

func _on_pressed() -> void:
	# on supprime toutes les musiques dans toutes les qualités
	var old_qualite = Settings.get_setting("qualite")
	var old_commun = Settings.get_setting("telechargements")["est commun"]
	
	Settings.get_setting("telechargements")["est commun"] = 0
	for qualite in ["min", "moy", "max"]:
		Settings.set_setting("qualite", qualite)
		script_get_ressource.supprimer_musiques(Settings.get_setting("telechargements")["musiques"].keys())
	Settings.get_setting("telechargements")["est commun"] = 1
	script_get_ressource.supprimer_musiques(Settings.get_setting("telechargements")["musiques"].keys())
	
	# on remet les paramètres qu'il y avait avant
	Settings.set_setting("qualite", old_qualite)
	Settings.get_setting("telechargements")["est commun"] = old_commun
	
	maj_dl_numbers.emit()
	
func _ready() -> void:
	script_get_ressource = Client.get_tree().get_first_node_in_group("easy_get_ressource")
