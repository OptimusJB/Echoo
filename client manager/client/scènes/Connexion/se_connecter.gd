extends Button

var disconnect_notif = true

func _on_pressed() -> void:
	if Client.is_locked:
		Notif.add_notif("NOT_ALLOWED")
		return
		
	# on vérifie que le nom et le mot de passe sont valides
	if not $"../select_nom".text or not $"../select_mdp".text:
		Notif.add_notif("INVALID_INFOS")
		return
	
	# on vérifie que le cooldown est terminé
	if not $cooldown.is_stopped():
		Notif.add_notif("COOLDOWN")
		return
		
	Client.is_locked = true
	# on regarde si on est déhà connecté au serveur
	if Client.socket.get_ready_state() == Client.socket.STATE_OPEN:
		connected()
	else:
		# on tente la connexion
		Client.url = Settings.get_setting("type connexion") + "://" + Settings.get_setting("ip")
		Client.port = FonctionsGlobal.to_int(Settings.get_setting("port"))
		Notif.add_notif("LOGGING_IN")
		if Client.connexion_serveur() < 0:
			Notif.add_notif("CONNECTION_FAILED")
			Client.is_locked = false
			return
	
	# on lance l'animation du logo
	get_tree().get_first_node_in_group("animation logo").play("battement")
	
	#set_process(true) # pour checker si ça réussit ou échoue

func connected():
	# connexion réussie
	# on réupère le pseudo et le mot de passe
	FonctionsGlobal.pseudo = $"../select_nom".text
	FonctionsGlobal.mdp = $"../select_mdp".text
	
	# on envoie
	Client.noeud_appelant = self
	await Client.send(JSON.stringify({"type":"se connecter", "pseudo":FonctionsGlobal.pseudo, "mdp":FonctionsGlobal.mdp}))

func received(message_json, _message_bytes):
	get_tree().get_first_node_in_group("animation logo").play("RESET")
	if not Client.check_keys(message_json, ["type", "resultat"]):
		push_error("clés invalides")
		Client.socket.close()
		Client.is_locked = false
		return
		
	if message_json["type"] == "se connecter":
		if message_json["resultat"] == "oui":
			# réussite de la connexion, on stocke les infos du serveur
			#print("résultat connexion : ", message_json)
			FonctionsGlobal.id_serveur = FonctionsGlobal.to_int(message_json["id serveur"])
			FonctionsGlobal.taille_envoi_fichier = FonctionsGlobal.to_float(message_json["taille envoi fichier"])
			FonctionsGlobal.id_current_download = null
			FonctionsGlobal.start_music_selected = null
			FonctionsGlobal.id_musique_ajout = null
			get_tree().change_scene_to_file("res://client/scènes/Accueil/Accueil.tscn")
			#get_tree().change_scene_to_packed(preload("res://client/scènes/Accueil/Accueil.tscn"))
		
		elif message_json["resultat"] == "non":
			# mot de passe invalide
			Notif.add_notif("WRONG_PASSWORD")
			#Client.socket.close()
			$cooldown.start()
			
		elif message_json["resultat"] == "new":
			# nouveau compte
			$"../nouveau compte".visible = true
	Client.is_locked = false
	
func disconnected():
	if disconnect_notif:
		Notif.add_notif("CONNECTION_FAILED")
	else:
		disconnect_notif = true
	Client.is_locked = false
	
	# on arrête l'animation du logo
	get_tree().get_first_node_in_group("animation logo").play("RESET")
	
func _ready() -> void:
	set_process(false)
	Client.connected.connect(connected)
	Client.disconnected.connect(disconnected)
