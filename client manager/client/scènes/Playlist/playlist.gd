extends PanelContainer
class_name Playlist

var id:int

signal supprimer_playlist_received
signal charger_playlist
signal ajouter_musique_playlist

var style_normal = null
var style_hover = null

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
		var sous_menu = get_tree().get_first_node_in_group("sous menu")
		sous_menu.creer_sous_menu(self, [tr("OPEN_PLAYLIST"), tr("DELETE_PLAYLIST")])

func delete_playlist():
	if Client.is_locked:
		Notif.add_notif("NOT_ALLOWED")
		return
	Client.is_locked = true
	
	# on envoie la requête au serveur
	Client.noeud_appelant = self
	await Client.send(JSON.stringify({"type":"supprimer playlist", "id_playlist":FonctionsGlobal.to_text(id)}))
	
	var resultat = await supprimer_playlist_received
	
	# on supprime la playlist de l'affichage
	queue_free()
	
	# on enlève l'affichage si c'est cette playlist
	var noeud_affichage_actuel = get_tree().get_first_node_in_group("enumeration").get_child(0)
	if noeud_affichage_actuel is MusicView and noeud_affichage_actuel.type_chargement == "playlist" and noeud_affichage_actuel.id_chargement == id:
		noeud_affichage_actuel.get_node("../").clear_affichage()
	
	Client.is_locked = false
		
func action(action_choisie):
	if action_choisie ==  tr("DELETE_PLAYLIST"):
		delete_playlist()
	elif action_choisie == tr("OPEN_PLAYLIST"):
		charger_playlist.emit(id)


func _on_charger_playlist_pressed() -> void:
	if FonctionsGlobal.id_musique_ajout == null:
		charger_playlist.emit(id)
	else:
		if Client.is_locked:
			Notif.add_notif("NOT_ALLOWED")
			return
		Client.is_locked = true
		
		# on ajoute la musique a la playlist
		var id_musique_ajout = FonctionsGlobal.id_musique_ajout
		FonctionsGlobal.id_musique_ajout = null
		
		Client.noeud_appelant = self
		await Client.send(JSON.stringify({"type":"ajouter musique playlist", "id_playlist":FonctionsGlobal.to_text(id), "id_musique":FonctionsGlobal.to_text(id_musique_ajout)}))
		var resultat = await ajouter_musique_playlist
		
		# on check si la playlist est ouverte, si oui on ajoute la musique
		var noeud_affichage_actuel = get_tree().get_first_node_in_group("enumeration").get_child(0)
		if noeud_affichage_actuel is MusicView and noeud_affichage_actuel.type_chargement == "playlist" and noeud_affichage_actuel.id_chargement == id:
			noeud_affichage_actuel.ajouter_musiques(resultat[0]["resultat"])
		
		Client.is_locked = false
		
func received(message_json, message_bytes):
	if not Client.check_keys(message_json, ["type", "resultat"]):
		push_error("clés invalides")
		Client.socket.close()
		Client.is_locked = false
		return
	if message_json["type"] == "supprimer playlist":
		supprimer_playlist_received.emit(message_json, message_bytes)
	elif message_json["type"] == "ajouter musique playlist":
		ajouter_musique_playlist.emit(message_json, message_bytes)
		
func _ready() -> void:
	# on connecte le signal à enumeration
	var noeud_enumeration = get_tree().get_first_node_in_group("enumeration")
	charger_playlist.connect(noeud_enumeration._playlist_clicked)

func _process(delta: float) -> void:
	# on regarde si une musique est en cours d'ajout
	if FonctionsGlobal.id_musique_ajout != null:
		if $"charger playlist".has_theme_stylebox_override("normal"):
			if style_normal == null:
				style_normal = $"charger playlist".get_theme_stylebox("normal").duplicate()
				style_hover = $"charger playlist".get_theme_stylebox("hover").duplicate()
			$"charger playlist".remove_theme_stylebox_override("normal")
			$"charger playlist".remove_theme_stylebox_override("hover")
	elif not $"charger playlist".has_theme_stylebox_override("normal"):
		$"charger playlist".add_theme_stylebox_override("normal", style_normal)
		$"charger playlist".add_theme_stylebox_override("hover", style_hover)
