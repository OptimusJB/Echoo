extends ScrollContainer

class_name settings_view
func charger(noeud_enumeration):
	# pas besoin du client mais on lock quand même pour éviter les bugs bizarres
	if Client.is_locked:
		Notif.add_notif("NOT_ALLOWED")
		return
	Client.is_locked = true
	# "echelle":1.0, "ip":"", "port":25565, "type connexion":"wss", "charger images":1, "cache max":100, "type son":0, "qualite":"max", "volume":1.0, "generer mipmaps":1, "commencer à la chanson cliquee":0, "langue":"", commun=1
	# on met les valeurs
	$"éléments/langue/HBoxContainer/options langue".selected = {"fr":0, "en":1}[Settings.get_setting("langue")]
	$"éléments/échelle/HBoxContainer/nombre échelle".value = Settings.get_setting("echelle")
	$"éléments/charger images/HBoxContainer/bouton charger images".button_pressed = Settings.get_setting("charger images")
	$"éléments/cache max/HBoxContainer/nombre cache max".value = Settings.get_setting("cache max")
	$"éléments/type son/HBoxContainer/options type son".selected = Settings.get_setting("type son")
	$"éléments/qualite/HBoxContainer/options qualite".selected = {"max":0, "moy":1, "min":2}[Settings.get_setting("qualite")]
	$"éléments/lisser images/HBoxContainer/bouton lisser images".button_pressed = Settings.get_setting("generer mipmaps")
	$"éléments/commencer chanson clic/HBoxContainer/bouton chanson clic".button_pressed = Settings.get_setting("commencer à la chanson cliquee")
	$"éléments/commun/HBoxContainer/bouton commun".button_pressed = Settings.get_setting("telechargements")["est commun"]
	
	# on add_child la scène
	for enfant in noeud_enumeration.get_children():
		enfant.queue_free()
	await Client.get_tree().process_frame # on attend que les enfant soient supprimés (pas de problème de nom)
	noeud_enumeration.add_child(self)
	
	Client.is_locked = false
