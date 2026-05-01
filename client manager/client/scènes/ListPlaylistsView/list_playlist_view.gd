extends PanelContainer
var script_get_ressource = preload("res://client/scènes/Accueil/easy_get_ressource.gd").new()
var noeud_playlist = preload("res://client/scènes/Playlist/Playlist.tscn")

signal creer_playlist_received
signal get_playlists_received

func charger_playlists():
	# on supprime toutes les playlists potentiellement existantes
	for i in range(2, $"liste playlists".get_child_count()):
		$"liste playlists".get_child(i).queue_free()
		
	$"liste playlists/chargement".visible = true
	while Client.is_locked:
		await get_tree().process_frame
	Client.is_locked = true
	
	# on envoie la requête au serveur
	Client.noeud_appelant = self
	Client.send(JSON.stringify({"type":"get playlists"}))
	
	var resultat = await get_playlists_received
	# on ajoute les playlists
	var new_playlist
	for playlist in resultat[0]["resultat"]:
		new_playlist = noeud_playlist.instantiate()
		new_playlist.id = FonctionsGlobal.to_int(playlist["id"])
		new_playlist.get_node("marges/éléments/nom").text = playlist["nom"]
		new_playlist.get_node("marges/éléments/cache/image").texture = await script_get_ressource.easy_get_image(playlist["image"])
		$"liste playlists".add_child(new_playlist)
		
	$"liste playlists/chargement".visible = false
	Client.is_locked = false
	
func _ready() -> void:
	# on charge les playlists
	await charger_playlists()
	
func _on_ajouter_playlist_pressed() -> void:
	if Client.is_locked:
		Notif.add_notif("NOT_ALLOWED")
		return
	Client.is_locked = true
	

	# on envoie la requête au serveur
	Client.noeud_appelant = self
	Client.send(JSON.stringify({"type":"creer playlist"}))
	
	var resultat = await creer_playlist_received
	
	# on ajoute la playlist
	var new_playlist = noeud_playlist.instantiate()
	new_playlist.id = FonctionsGlobal.to_int(resultat[0]["resultat"])
	new_playlist.get_node("marges/éléments/nom").text = "Playlist"
	$"liste playlists".add_child(new_playlist)
	
	Client.is_locked = false
	
func received(message_json, message_bytes):
	if not Client.check_keys(message_json, ["type", "resultat"]):
		push_error("clés invalides")
		Client.socket.close()
		Client.is_locked = false
		return
	if message_json["type"] == "creer playlist":
		creer_playlist_received.emit(message_json, message_bytes)
	elif message_json["type"] == "get playlists":
		get_playlists_received.emit(message_json, message_bytes)
