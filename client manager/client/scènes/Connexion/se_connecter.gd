extends Button

func _on_pressed() -> void:
	if Client.is_locked:
		Notif.add_notif(tr("NOT_ALLOWED"))
		return
		
	# on vérifie que le nom et le mot de passe sont valides
	if not $"../select_nom".text or not $"../select_mdp".text:
		Notif.add_notif(tr("INVALID_INFOS"))
		return
	
	# on tente la connexion
	Client.is_locked = true
	Client.url = Settings.get_setting("type connexion") + "://" + Settings.get_setting("ip")
	Client.port = FonctionsGlobal.to_int(Settings.get_setting("port"))
	Notif.add_notif(tr("LOGGING_IN"))
	if Client.connexion_serveur() < 0:
		Notif.add_notif(tr("CONNECTION_FAILED"))
		Client.is_locked = false
		return
	
	# on lance l'animation du logo
	get_tree().get_first_node_in_group("animation logo").play("battement")
	
	#set_process(true) # pour checker si ça réussit ou échoue

func connected():
	# connexion réussie
	# mettre ici fonction permettant d'envoyer la demande de connexion
	pass

func disconnected():
	Notif.add_notif(tr("CONNECTION_FAILED"))
	Client.is_locked = false
	
	# on arrête l'animation du logo
	get_tree().get_first_node_in_group("animation logo").play("RESET")
	
func _ready() -> void:
	set_process(false)
	Client.connected.connect(connected)
	Client.disconnected.connect(disconnected)
