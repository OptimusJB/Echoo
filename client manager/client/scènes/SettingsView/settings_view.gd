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
	
	# on add_child la scène
	for enfant in noeud_enumeration.get_children():
		enfant.queue_free()
	noeud_enumeration.add_child(self)
	
	Client.is_locked = false
