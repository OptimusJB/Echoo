extends Node
signal image_received

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
	image_received.emit(message_json, message_bytes)
