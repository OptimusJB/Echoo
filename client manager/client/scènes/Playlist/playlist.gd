extends PanelContainer

var id:int

signal supprimer_playlist_received
signal charger_playlist

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
	Client.send(JSON.stringify({"type":"supprimer playlist", "id_playlist":FonctionsGlobal.to_text(id)}))
	
	var resultat = await supprimer_playlist_received
	
	# on supprime la playlist de l'affichage
	queue_free()
	
	Client.is_locked = false

func received(message_json, message_bytes):
	if not Client.check_keys(message_json, ["type", "resultat"]):
		push_error("clés invalides")
		Client.socket.close()
		Client.is_locked = false
		return
	if message_json["type"] == "supprimer playlist":
		supprimer_playlist_received.emit(message_json, message_bytes)
		
func action(action_choisie):
	if action_choisie ==  tr("DELETE_PLAYLIST"):
		delete_playlist()
	elif action_choisie == tr("OPEN_PLAYLIST"):
		charger_playlist.emit(id)


func _on_charger_playlist_pressed() -> void:
	charger_playlist.emit(id)

func _ready() -> void:
	# on connecte le signal à enumeration
	var noeud_enumeration = get_tree().get_first_node_in_group("enumeration")
	charger_playlist.connect(noeud_enumeration._playlist_clicked)
