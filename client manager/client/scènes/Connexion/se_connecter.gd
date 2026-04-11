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
	
	set_process(true) # pour checker si ça réussit ou échoue

func _ready() -> void:
	set_process(false)

func _process(delta: float) -> void:
	# fonction pour cheker la réussite ou l'échec de la connexion au serveur
	var state = Client.socket.get_ready_state()
	if state == WebSocketPeer.STATE_CLOSED:
		Notif.add_notif(tr("CONNECTION_FAILED"))
		Client.is_locked = false
		set_process(false)
		
	elif state == WebSocketPeer.STATE_OPEN:
		# connexion réussie
		print("connexion réussie")
		# mettre ici fonction permettant d'envoyer la demande de connexion
		
		set_process(false)
