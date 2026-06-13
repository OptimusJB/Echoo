extends Control
var chemin_image = null
var id_playlist_actuelle:int
var image_playlist_actuelle:String

signal set_playlist_infos_received

func _on_fond_decharger_settings() -> void:
	visible = false


func _on_file_dialog_file_selected(path: String) -> void:
	# on tente de charger l'image
	var old_chemin_image = chemin_image
	chemin_image = path
	
	# on regarde si l'image est valide ne dépasse pas la taille max
	if not chemin_image.get_extension() in ["png", "jpg", "jpeg", "bmp", "svg"]:
		chemin_image = old_chemin_image
		Notif.add_notif("INVALID_IMAGE")
		return
		
	var fichier_read = FileAccess.get_file_as_bytes(chemin_image)
	if not fichier_read:
		chemin_image = old_chemin_image
		push_error("impossible d'ouvrir le fichier")
		return
	if float(len(fichier_read)) / 1.049e+6 > FonctionsGlobal.taille_envoi_fichier:
		chemin_image = old_chemin_image
		Notif.add_notif(tr("IMAGE_TOO_BIG") % [FonctionsGlobal.taille_envoi_fichier])
		return
	$"fond informations/éléments/infos/gauche/cache/image".texture = RessourceLoad.easy_get_image(chemin_image)
	
func charger_settings(id_playlist:int, image_playlist:String, nom_playlist:String, description:String, texture_image):
	id_playlist_actuelle = id_playlist
	image_playlist_actuelle = image_playlist
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
	$fond.can_remove = false
	
	var nom_playlist = $"fond informations/éléments/infos/droite/nom".text
	var description = $"fond informations/éléments/infos/droite/description".text
	
	Client.noeud_appelant = self
	# on regarde si l'image a été modifiée, si oui on la récupère
	var extension = null
	if chemin_image != null:
		extension = chemin_image.get_extension() # extension sans le .
		print("envoi image")
		var envoi_fichier = await Client.send_file(chemin_image)
		if not envoi_fichier:
			Notif.add_notif("INFORMATION_FAIL")
			Client.is_locked = false
			return
		print("image envoyée")
	
	await Client.send(JSON.stringify({"type":"set playlist infos", "id_playlist":FonctionsGlobal.to_text(id_playlist_actuelle), "nom_playlist":nom_playlist, "description":description, "image_extension":extension}))
	
	await set_playlist_infos_received
	visible = false
	Notif.add_notif("UPDATED_INFORMATION")
	
	# on supprime dans RessourceLoad si l'image a changé
	if image_playlist_actuelle in RessourceLoad.loaded.keys():
		RessourceLoad.supprimer_ressource(image_playlist_actuelle)
	
	# on change les infos et l'image du header de la playlist ouverte
	var noeud_header = get_tree().get_first_node_in_group("enumeration").get_node("MusicView/liste/HeaderPlaylist")
	if chemin_image:
		noeud_header.get_node("éléments/masque/image").texture = RessourceLoad.easy_get_image(chemin_image)
	noeud_header.get_node("éléments/marges/textes/nom").text = nom_playlist
	noeud_header.get_node("éléments/marges/textes/description").text = description
	
	# on change le nom et l'image de la playlist dans la liste des playlists
	var noeud_playlist = get_tree().get_first_node_in_group("ListPlaylistView")
	for playlist in noeud_playlist.get_node("liste playlists").get_children():
		if playlist is Playlist and playlist.id == id_playlist_actuelle:
			if chemin_image:
				playlist.get_node("marges/éléments/cache/image").texture = RessourceLoad.easy_get_image(chemin_image)
			playlist.get_node("marges/éléments/nom").text = nom_playlist
	
	# on change le nom enregistré dans le player
	var noeud_player = get_tree().get_first_node_in_group("player")
	noeud_player.nom_playlist = nom_playlist
	
	Client.is_locked = false
	$fond.can_remove = true

func received(message_json, message_bytes):
	if not Client.check_keys(message_json, ["type", "resultat"]):
		push_error("clés invalides")
		Client.socket.close()
		return
	if message_json["type"] == "set playlist infos":
		set_playlist_infos_received.emit(message_json, message_bytes)
