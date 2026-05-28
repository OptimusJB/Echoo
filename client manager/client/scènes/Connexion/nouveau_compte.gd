extends VBoxContainer

func received(message_json, _message_bytes):
	if not Client.check_keys(message_json, ["type", "resultat"]):
		push_error("clés invalides")
		Client.socket.close()
		Client.is_locked = false
		return
	
	if message_json["type"] == "nouveau compte":
		if message_json["resultat"] == "oui":
			Notif.add_notif("NEW_SUCCESS")
		else:
			Notif.add_notif("NEW_FAIL")
	Client.is_locked = false

func _on_oui_création_pressed() -> void:
	# on envoie la demande au serveur
	if Client.is_locked:
		Notif.add_notif("NOT_ALLOWED")
		return
	
	Client.is_locked = true
	
	Client.noeud_appelant = self
	await Client.send(JSON.stringify({"type":"nouveau compte", "pseudo":FonctionsGlobal.pseudo, "mdp":FonctionsGlobal.mdp}))
	visible = false

func _on_non_création_pressed() -> void:
	visible = false
