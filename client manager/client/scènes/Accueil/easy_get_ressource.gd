extends Node
signal image_received
signal music_received

# ATTENTION les fonctions ne vérifient pas Client.is_locked

func easy_get_music(id_musique, qualite):
	# on demande la musique au serveur
	Client.noeud_appelant = self
	Client.send(JSON.stringify({"type":"get music", "id":id_musique, "qualite":qualite}))
	var reponse = await music_received
	
	# on vérifie qu'une qualité est disponible
	if reponse[0]["qualite"] == "non":
		Notif.add_notif("NO_QUALITY")
		return "no quality"
		
	var extension = reponse[0]["resultat"]	# avec le '.' devant
	
	# on charge la musique
	#print("octets reçus : ", len(reponse[1]))
	var musique_stream
	if extension == ".mp3":
		musique_stream = AudioStreamMP3.load_from_buffer(reponse[1])
	elif extension == ".ogg":
		musique_stream = AudioStreamOggVorbis.load_from_buffer(reponse[1])
	elif extension == ".wav":
		musique_stream = AudioStreamWAV.load_from_buffer(reponse[1])
	else:
		return null
	if not musique_stream:	# load_from_buffer renvoie null si échoué
		return null
	
	if reponse[0]["qualite"] != qualite:
		Notif.add_notif(tr("QUALITY_NOT_AVAILABLE") % [qualite, reponse[0]["qualite"]])
	return musique_stream
	
func easy_get_image(chemin_image):
	if not chemin_image:
		RessourceLoad.set_icone_base(chemin_image)
		return RessourceLoad.icone_base

	# on regarde si l'image est chargée
	var image
	if RessourceLoad.is_loaded(chemin_image):
		image = RessourceLoad.get_ressource(chemin_image)
		if not image:
			RessourceLoad.set_icone_base(chemin_image)
			image = RessourceLoad.icone_base
	elif not Settings.get_setting("charger images"):
		RessourceLoad.set_icone_base(chemin_image)
		image = RessourceLoad.icone_base
	else:
		# on importe l'image
		Client.noeud_appelant = self
		Client.send(JSON.stringify({"type":"get image", "image":chemin_image}))
		var reponse = await image_received
		
		# on charge l'image
		RessourceLoad.charger_ressource(chemin_image, reponse[1], Settings.get_setting("cache max"))
		image = RessourceLoad.get_ressource(chemin_image)
		if not image:
			RessourceLoad.set_icone_base(chemin_image)
			image = RessourceLoad.icone_base
	return image

func received(message_json, message_bytes):
	if not Client.check_keys(message_json, ["type", "resultat"]):
		push_error("clés invalides")
		Client.socket.close()
		return
	if message_json["type"] == "get image":
		image_received.emit(message_json, message_bytes)
	else:
		if not Client.check_keys(message_json, ["qualite"]):
			push_error("clés invalides")
			Client.socket.close()
			return
		music_received.emit(message_json, message_bytes)
