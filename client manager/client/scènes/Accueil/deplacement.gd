extends PanelContainer

var id_playlist = null
var position_musique_depart = null
var position_musique_fin = null
var actif = false

signal changer_position_musique_received

func lancer_deplacement(id_playlist_musique, position_musique, noeud_image_musique:TextureRect):
	if Client.is_locked:
		return
	id_playlist = id_playlist_musique
	position_musique_depart = position_musique
	position_musique_fin = position_musique
	$image.texture = noeud_image_musique.texture.duplicate()
	visible = true
	actif = true
	set_process(true)

func survol(position_musique):
	if actif:
		position_musique_fin = position_musique

func fin_deplacement():
	if not actif:
		return
	print("début : ", position_musique_depart, ", fin :", position_musique_fin)
	actif = false
	set_process(false)
	visible = false
	if position_musique_depart == position_musique_fin:
		return
		
	if Client.is_locked:
		Notif.add_notif("NOT_ALLOWED")
		return
	Client.is_locked = true
	
	# on envoie la requête au serveur
	Client.noeud_appelant = self
	await Client.send(JSON.stringify({"type":"changer position musique", "id_playlist":FonctionsGlobal.to_text(id_playlist), "position_debut":FonctionsGlobal.to_text(position_musique_depart + 1), "position_fin":FonctionsGlobal.to_text(position_musique_fin + 1)}))
	await changer_position_musique_received
	
	# on lance la procédure de changement de position dans le MusicView
	# ATTENTION si plusieurs enfants ça marche pas
	var noeud_music_view = get_tree().get_first_node_in_group("enumeration").get_child(0)
	if not noeud_music_view is MusicView:
		push_error("pas un noeud MusicView, plusieurs enfants ?")
		return
	noeud_music_view.deplacer_musiques(position_musique_depart, position_musique_fin)
	Client.is_locked = false
	
func received(message_json, message_bytes):
	if not Client.check_keys(message_json, ["type", "resultat"]):
		push_error("clés invalides")
		Client.socket.close()
		Client.is_locked = false
		return
	if message_json["type"] == "changer position musique":
		changer_position_musique_received.emit(message_json, message_bytes)

func _ready() -> void:
	set_process(false)
	
func _process(_delta: float) -> void:
	if actif:
		global_position = get_global_mouse_position()
