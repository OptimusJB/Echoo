extends HBoxContainer
var script_get_ressource = preload("res://client/scènes/Accueil/easy_get_ressource.gd").new()

var nom_playlist = ""
var playlist = []
var infos_musiques = {}	# clé:id musique, valeur:{"position", "nom", "id_artiste", "nom_artiste", "id_album", "nom_album", "image"}

var position_play = -1	# position actuelle de la musique jouée dans playlist_play
var position_play_debut = -1 # première musique jouée (pour savoir où ça commence si on enlève l'aléatoire)

var playlist_play = []	# copie de playlist, en lien avec ce qui est joué actuellement
var playlist_play_no_random = []	# playlist_play mais pas random
var infos_musiques_play = {}

var player_grab = false	# true si la barre du player est maintenue

signal update_queue
signal charger_artiste

func shuffle_playlist():
	playlist_play_no_random = playlist_play.duplicate()
	var id_musique_actuelle = playlist_play.pop_at(position_play)
	playlist_play.shuffle()
	playlist_play.insert(0, id_musique_actuelle)
	position_play = 0
	
func received(message_json, _message_bytes):
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
		Client.is_locked = false
		_on_suivant_pressed()
		return
	else:
		if musique is String and musique == "no quality":
			Client.is_locked = false
			_on_suivant_pressed()
			return
			
		$"../AudioStreamPlayer".stream = musique
		
		# on change le mix target
		if $"../AudioStreamPlayer".mix_target != FonctionsGlobal.to_int(Settings.get_setting("type son")):
			$"../AudioStreamPlayer".mix_target = FonctionsGlobal.to_int(Settings.get_setting("type son"))
		
		# on change les infos sur le player
		$"centre/slider/temps actuel".text = FonctionsGlobal.secondes_to_text(0)
		$"centre/slider/temps max".text = FonctionsGlobal.secondes_to_text($"../AudioStreamPlayer".stream.get_length())
		$"gauche/masque/image musique".texture = await script_get_ressource.easy_get_image(infos["image_musique"])
		$"gauche/infos musique/nom".text = FonctionsGlobal.to_text(infos["nom_musique"])
		$"gauche/infos musique/artiste".text = FonctionsGlobal.to_text(infos["nom_artiste"])
		
		# on met à jour le slider
		$"centre/slider/barre".max_value = $"../AudioStreamPlayer".stream.get_length()
		$"centre/slider/barre".value = 0.0
		
		# on met le bouton sur pause
		$"centre/boutons/size jouer/jouer".button_pressed = true
		
		$"../".visible = true
		$"../AudioStreamPlayer".play()
		
	Client.is_locked = false
	
func jouer_musique(position_musique:int):
	if Client.is_locked:
		Notif.add_notif("NOT_ALLOWED")
		
		# on cache le player s'il n'y a pas de musique
		if not $"../AudioStreamPlayer".has_stream_playback():
			$"../".visible = false
		return
	Client.is_locked = true
	
	# on s'arrête si position_musique est suspect
	if position_musique < 0:
		Client.is_locked = false
		return
		
	# on coupe la musique en cours s'il y en a une
	$"../AudioStreamPlayer".stop()
	
	position_play = position_musique
	
	# on change la file d'attente
	update_queue.emit()
	
	# on demande les infos de la musique au serveur
	Client.noeud_appelant = self
	await Client.send(JSON.stringify({"type":"get music infos", "id":FonctionsGlobal.to_text(playlist_play[position_musique])}))
	
func creer_playlist_play(position_playlist:int):
	if Client.is_locked:
		Notif.add_notif("NOT_ALLOWED")
		return
		
	if position_playlist >= len(playlist):
		push_error("position_playlist trop grand")
		return
	
	if Settings.get_setting("commencer à la chanson cliquee"):
		playlist_play = playlist.slice(position_playlist, len(playlist))
		position_play = 0
	else:
		playlist_play = playlist.slice(0, len(playlist))
		position_play = position_playlist
	
	playlist_play_no_random = playlist_play.duplicate()
	infos_musiques_play = infos_musiques.duplicate()
	position_play_debut = position_playlist
	
	# on shuffle si le bouton est cliqué
	if $"centre/boutons/size aléatoire/aléatoire".button_pressed:
		shuffle_playlist()
		
	# on met le bon volume
	$"../AudioStreamPlayer".volume_linear = FonctionsGlobal.to_float(Settings.get_setting("volume"))
	$"droite/barre volume".value = FonctionsGlobal.to_float(Settings.get_setting("volume"))
	
	# on retire le repeat
	$"centre/boutons/size repeter/repeter".reset()
		
	jouer_musique(position_play)


func _on_timer_refresh_timeout() -> void:
	# on met à jour le slider et le temps
	if not get_window().has_focus() or not $"../AudioStreamPlayer".has_stream_playback() or player_grab:
		return
	
	var avancement = $"../AudioStreamPlayer".get_playback_position()
	$"centre/slider/barre".value = float(int(avancement))
	$"centre/slider/temps actuel".text = FonctionsGlobal.secondes_to_text(avancement)
	#print(avancement)
	#print($"centre/slider/barre".value, " et ", $"centre/slider/temps actuel".text)

func _on_barre_drag_started() -> void:
	player_grab = true

func changer_position(new_position):
	var was_paused = $"../AudioStreamPlayer".stream_paused
	
	$"../AudioStreamPlayer".stream_paused = false	# seek ne fonctionne pas si aucun son ne joue
	$"../AudioStreamPlayer".seek(min(new_position, $"../AudioStreamPlayer".stream.get_length() - 0.01))
	if was_paused:
		$"../AudioStreamPlayer".stream_paused = true
		
func _on_barre_drag_ended(value_changed: bool) -> void:
	player_grab = false
	# on change la position de lecture
	changer_position($"centre/slider/barre".value)

func _on_barre_value_changed(value: float) -> void:
	$"centre/slider/temps actuel".text = FonctionsGlobal.secondes_to_text(int(value))


func _on_jouer_toggled(toggled_on: bool) -> void:
	# toggled_on --> en cours de lecture --> texture pause
	#print("toggled")
	if toggled_on:
		$"../AudioStreamPlayer".stream_paused = false
	else:
		$"../AudioStreamPlayer".stream_paused = true


func _on_audio_stream_player_finished() -> void:
	if Client.is_locked:
		
		Notif.add_notif("NOT_ALLOWED")
		# on cache le player s'il n'y a pas de musique
		if not $"../AudioStreamPlayer".has_stream_playback():
			$"../".visible = false
		return
		
	var noeud_repeat = $"centre/boutons/size repeter/repeter"
	# musique finie, on check s'il y a une musique suivante
	if noeud_repeat.etat_texte[noeud_repeat.etat] == "track":
		# on relance la même musique
		#jouer_musique(position_play) # pas optimisé car on a déjà les données
		
		# on change le mix target
		if $"../AudioStreamPlayer".mix_target != FonctionsGlobal.to_int(Settings.get_setting("type son")):
			$"../AudioStreamPlayer".mix_target = FonctionsGlobal.to_int(Settings.get_setting("type son"))
		
		# on remet bien le bouton lecture
		$"centre/boutons/size jouer/jouer".button_pressed = true
		$"../AudioStreamPlayer".play()
		return
		
	if position_play >= len(playlist_play) - 1:
		# on check si on est en repeat on, sinon on arrête le player
		if noeud_repeat.etat_texte[noeud_repeat.etat] == "on":
			jouer_musique(0)
		else:
			$"../".visible = false
			$"../AudioStreamPlayer".stop()	# si jamais c'est suivant qui a appelé
			position_play += 1	# pour ne rien afficher dans la liste d'attente
			update_queue.emit()
	else:
		jouer_musique(position_play + 1)

func _on_suivant_pressed() -> void:
	_on_audio_stream_player_finished()

func _on_precedent_pressed() -> void:
	if position_play == 0 or $"../AudioStreamPlayer".get_playback_position() >= 5.0 or $"centre/boutons/size repeter/repeter".etat_texte[$"centre/boutons/size repeter/repeter".etat] == "track":
		# on change la position de lecture
		changer_position(0.0)
	else:
		if Client.is_locked:
			Notif.add_notif("NOT_ALLOWED")
			return
		jouer_musique(position_play - 1)


func _on_barre_volume_value_changed(value: float) -> void:
	# on modifie les settings et le son (sans sauvegarder pour éviter de le faire à la chaine)
	Settings.set_setting("volume", $"droite/barre volume".value, false)
	$"../AudioStreamPlayer".volume_linear = FonctionsGlobal.to_float(Settings.get_setting("volume"))


func _on_barre_volume_drag_ended(value_changed: bool) -> void:
	# on sauvegarde le volume
	Settings.save_settings()


func _on_aléatoire_toggled(toggled_on: bool) -> void:
	if $"../AudioStreamPlayer".has_stream_playback():
		if toggled_on:
			# on shuffle
			shuffle_playlist()
		else:
			# on remet le bon ordre
			# note : s'il y a plusieurs musiques pareilles, on suppose qu'on est au premier
			var id_musique_actuelle = playlist_play[position_play]
			playlist_play = playlist_play_no_random.slice(0, len(playlist_play_no_random))
			position_play = playlist_play.find(id_musique_actuelle)
		
		update_queue.emit()


func _on_artiste_pressed() -> void:
	if $"../AudioStreamPlayer".has_stream_playback():
		charger_artiste.emit(infos_musiques_play[playlist_play[position_play]]["id_artiste"])
