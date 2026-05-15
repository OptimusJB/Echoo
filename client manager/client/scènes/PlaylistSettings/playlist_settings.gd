extends Control
var script_get_ressource = preload("res://client/scènes/Accueil/easy_get_ressource.gd").new()
var chemin_image = null
var id_playlist_actuelle:int

signal set_playlist_infos_received

func charger_playlist_settings(nom:String, description:String, image:String):
	$"fond informations/éléments/infos/droite/nom".text = FonctionsGlobal.to_text(nom)
	$"fond informations/éléments/infos/droite/description".text = FonctionsGlobal.to_text(description)
	$"fond informations/éléments/infos/gauche/cache/image".texture = await script_get_ressource.easy_get_image(image)
	visible = true

func _on_fond_decharger_settings() -> void:
	visible = false


func _on_file_dialog_file_selected(path: String) -> void:
	# on tente de charger l'image
	chemin_image = path
	$"fond informations/éléments/infos/gauche/cache/image".texture = RessourceLoad.easy_get_image(chemin_image)
	
func charger_settings(id_playlist:int, nom_playlist:String, description:String, texture_image):
	id_playlist_actuelle = id_playlist
	$"fond informations/éléments/infos/droite/nom".text = nom_playlist
	$"fond informations/éléments/infos/droite/description".text = description
	$"fond informations/éléments/infos/gauche/cache/image".texture = texture_image
	chemin_image = null
	visible = true
	


func _on_valider_pressed() -> void:
	if Client.is_locked:
		Notif.add_notif("NOT_ALLOWED")
		return
	Client.is_locked = true
	
	var nom_playlist = $"fond informations/éléments/infos/droite/nom".text
	var description = $"fond informations/éléments/infos/droite/description".text
	
	# on regarde si l'image a été modifiée, si oui on la récupère
	var image_bytes = null
	var extension = null
	if chemin_image != null:
		image_bytes = FileAccess.get_file_as_bytes(chemin_image)
		extension = chemin_image.get_extension() # extension sans le .
		if not image_bytes:
			Notif.add_notif("INFORMATION_FAIL")
			Client.is_locked = false
			return
			
	# on envoie la requête au serveur
	Client.noeud_appelant = self
	if chemin_image != null:
		print("envoi image")
		await Client.send(image_bytes)
		print("image envoyée")
	await Client.send(JSON.stringify({"type":"set playlist infos", "id_playlist":FonctionsGlobal.to_text(id_playlist_actuelle), "nom_playlist":nom_playlist, "description":description, "image_extension":extension}))
	
	await set_playlist_infos_received
	visible = false
	Notif.add_notif("UPDATED_INFORMATION")
	Client.is_locked = false

func received(message_json, message_bytes):
	if not Client.check_keys(message_json, ["type", "resultat"]):
		push_error("clés invalides")
		Client.socket.close()
		return
	if message_json["type"] == "set playlist infos":
		set_playlist_infos_received.emit(message_json, message_bytes)
