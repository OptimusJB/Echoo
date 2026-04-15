extends ScrollContainer

func charger_recherche(noeud_enumeration:Node, recherche:String):
	# on envoie la recherche au serveur
	if Client.is_locked:
		# un autre recherche est probablement en cours
		# dans le doute on ne met pas la notif
		#Notif.add_notif(tr("NOT_ALLOWED"))
		return
	Client.is_locked = true
	
	Client.noeud_appelant = self
	Client.send(JSON.stringify({"type":"rechercher", "recherche":recherche, "nb charges":0}))

func received(message_json, _message_bytes):
	if not Client.check_keys(message_json, ["type", "resultat", "est fin"]):
		Client.socket.close()
		Client.is_locked = false
		return
		
	# on crée chaque noeud et on add_child
	
	Client.is_locked = false
