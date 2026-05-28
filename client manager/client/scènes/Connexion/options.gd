extends VBoxContainer


func _on_choisir_serveur_pressed() -> void:
	# on affiche les options tout en chargeant les différents éléments
	$select_ip.text = FonctionsGlobal.to_text(Settings.get_setting("ip"))
	$select_port.text = FonctionsGlobal.to_text(Settings.get_setting("port"))
	
	if not Settings.get_setting("type connexion") in ["wss", "ws"]:
		Settings.set_setting("type connexion", "wss")
	$radio.mode = Settings.get_setting("type connexion")
	$radio.check_pressed()
	visible = true
	
	# on affiche le bon bouton
	$"../choisir serveur".visible = false
	$"../valider".visible = true

func _on_valider_pressed() -> void:
	# on sauvegarde les paramètres
	Settings.set_setting("ip", $select_ip.text, false)
	Settings.set_setting("port", FonctionsGlobal.to_int($select_port.text), false)
	Settings.set_setting("type connexion", $radio.mode)
	visible = false
	
	# on affiche le bon bouton
	$"../valider".visible = false
	$"../choisir serveur".visible = true
	
	Notif.add_notif("NOTIF_SERVER_CHANGED")
	
	# on close le socket au cas où il est déjà ouvert
	Client.socket.close()
