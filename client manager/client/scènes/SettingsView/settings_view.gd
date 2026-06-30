extends ScrollContainer

class_name settings_view

var script_get_ressource = null
var nb_musiques = 0
var nb_images = 0

func afficher_dl_numbers():
	$"éléments/supprimer musiques/VBoxContainer/musiques".text = tr("SETTING_MUSICS_NUMBER") % [nb_musiques]
	$"éléments/supprimer musiques/VBoxContainer/images".text = tr("SETTING_IMAGES_NUMBER") % [nb_images]
	
func maj_dl_numbers():
	# on met à jour le nombre de musiques et images téléchargées
	nb_musiques = 0
	nb_images = 0
	for id_musique in Settings.get_setting("telechargements")["musiques"].keys():
		nb_musiques = nb_musiques + 4 - Settings.get_setting("telechargements")["musiques"][id_musique].values().count(null)
	for id_image in Settings.get_setting("telechargements")["images"].keys():
		nb_images = nb_images + 1
	afficher_dl_numbers()
	
func charger(noeud_enumeration):
	# pas besoin du client mais on lock quand même pour éviter les bugs bizarres
	if Client.is_locked:
		Notif.add_notif("NOT_ALLOWED")
		return
	Client.is_locked = true
	# "echelle":1.0, "ip":"", "port":25565, "type connexion":"wss", "charger images":1, "cache max":100, "type son":0, "qualite":"max", "volume":1.0, "generer mipmaps":1, "commencer à la chanson cliquee":0, "langue":"", commun=1
	# on met les valeurs
	$"éléments/langue/HBoxContainer/options langue".selected = {"fr":0, "en":1}[FonctionsGlobal.to_text(Settings.get_setting("langue"))]
	$"éléments/échelle/HBoxContainer/nombre échelle".value = FonctionsGlobal.to_float(Settings.get_setting("echelle"))
	$"éléments/charger images/HBoxContainer/bouton charger images".button_pressed = FonctionsGlobal.to_int(Settings.get_setting("charger images"))
	$"éléments/cache max/HBoxContainer/nombre cache max".value = FonctionsGlobal.to_int(Settings.get_setting("cache max"))
	$"éléments/type son/HBoxContainer/options type son".selected = FonctionsGlobal.to_int({0:0, 1:2, 2:1}[Settings.get_setting("type son")])
	$"éléments/qualite/HBoxContainer/options qualite".selected = FonctionsGlobal.to_int({"max":0, "moy":1, "min":2}[Settings.get_setting("qualite")])
	$"éléments/lisser images/HBoxContainer/bouton lisser images".button_pressed = FonctionsGlobal.to_int(Settings.get_setting("generer mipmaps"))
	$"éléments/commencer chanson clic/HBoxContainer/bouton chanson clic".button_pressed = FonctionsGlobal.to_int(Settings.get_setting("commencer à la chanson cliquee"))
	$"éléments/commun/HBoxContainer/bouton commun".button_pressed = FonctionsGlobal.to_int(Settings.get_setting("telechargements")["est commun"])
	
	# on met à jour le nombre de musiques et images téléchargées
	maj_dl_numbers()
	
	# on add_child la scène
	for enfant in noeud_enumeration.get_children():
		enfant.queue_free()
	await Client.get_tree().process_frame # on attend que les enfant soient supprimés (pas de problème de nom)
	noeud_enumeration.add_child(self)
	
	Client.is_locked = false

func _ready() -> void:
	script_get_ressource = Client.get_tree().get_first_node_in_group("easy_get_ressource")
