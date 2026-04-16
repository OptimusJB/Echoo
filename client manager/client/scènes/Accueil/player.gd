extends PanelContainer
var script_get_ressource = load("res://client/scènes/Accueil/easy_get_ressource.gd").new()

var nom_playlist = ""
var playlist = []
var position_play = null	# position actuelle de la musique jouée dans playlist_play

var playlist_play = []	# copie de playlist, en lien avec ce qui est joué actuellement

func received(message_json, message_bytes):
	if not Client.check_keys(message_json, ["type", "resultat"]):
		push_error("clés invalides")
		Client.socket.close()
		Client.is_locked = false
		return
	
	# on charge les différents éléments
	var infos = message_json["resultat"]
	var musique = await script_get_ressource.easy_get_music(playlist_play[position_play], FonctionsGlobal.to_text(Settings.get_setting("qualite")))
	
	if not musique:
		Notif.add_notif("GET_MUSIC_FAILED")
	else:
		$"AudioStreamPlayer".stream = musique
		
		# on change le mix target
		if $AudioStreamPlayer.mix_target != FonctionsGlobal.to_int(Settings.get_setting("type son")):
			$AudioStreamPlayer.mix_target = FonctionsGlobal.to_int(Settings.get_setting("type son"))
		visible = true
		$AudioStreamPlayer.play()
	Client.is_locked = false
	
func jouer_musique(position_musique:int):
	if Client.is_locked:
		Notif.add_notif("NOT_ALLOWED")
		return
	Client.is_locked = true
	
	# on coupe la musique en cours s'il y en a une
	$AudioStreamPlayer.stop()
	
	position_play = position_musique
	# on demande les infos de la musique au serveur
	Client.noeud_appelant = self
	Client.send(JSON.stringify({"type":"get music infos", "id":playlist_play[position_musique]}))
	
func creer_playlist_play(position_playlist:int):
	if Client.is_locked:
		Notif.add_notif("NOT_ALLOWED")
		return
		
	if position_playlist >= len(playlist):
		push_error("position_playlist trop grand")
		return
	
	playlist_play = playlist.slice(position_playlist, len(playlist))
	jouer_musique(0)
