extends PanelContainer
class_name objet_musique

var script_get_ressource = null
var player

var focus = false
var afficher_numero = true	# si false, le bouton n'apparaîtra pas quand on enlève la souris

var id:int
var id_artiste:int
var id_album:int
var position_playlist:int
var chemin_image:String

var dernier_refresh_playing = Time.get_ticks_msec()	# pour l'animation playing
var numero_frame_playing = 0
var noeud_animation_playing

var dernier_refresh_download = Time.get_ticks_msec() # pour l'animation download
var numero_frame_download = 0
var noeud_animation_download

var is_in_queue	= false	# mettre à true si jamais la musique est dans la file d'attente
var id_playlist = null

var est_telecharge = false

signal jouer_musique
signal creer_playlist

signal album_clicked
signal artiste_clicked

signal remove_from_playlist_received

func _on_mouse_entered() -> void:
	focus = true
	# on change la couleur du fond
	var stylebox = get_theme_stylebox("panel").duplicate()
	stylebox.bg_color = Color(0.279, 0.279, 0.279)
	add_theme_stylebox_override("panel", stylebox)
	
	afficher_indicateur()
	
	# on envoie l'info au deplacement
	var noeud_deplacement = get_tree().get_first_node_in_group("deplacement")
	noeud_deplacement.survol(position_playlist)

func _on_mouse_exited() -> void:
	focus = false
	# on change la couleur du fond
	var stylebox = get_theme_stylebox("panel").duplicate()
	stylebox.bg_color = Color(0.278, 0.278, 0.278, 0.0)
	add_theme_stylebox_override("panel", stylebox)
	
	afficher_indicateur()

func _ready():
	set_process(false)
	script_get_ressource = Client.get_tree().get_first_node_in_group("easy_get_ressource")
	
	# on check si l'image affichée est en réalité l'image téléchargée associée à la musique
	# en effet, si on télécharge une musique (et son image), et qu'entre temps l'image sur le serveur change, on privilégie l'image enregistrée sur le disque
	# dans ce cas, là, on remplace chemin_image
	# cela permet de garder une logique au niveau de l'affichage lors des enregistrements / suppressions
	# si on ne fait pas ça : par exemple, si on supprime du disque la musique avec l'ancienne image, mais que l'image récente est également téléchargée, l'icône d'image sera toujours affichée (ce n'est pas logique, car l'ancienne image est supprimée)
	var chemin_dl = script_get_ressource.get_image_path_of_downloaded_music(id)
	if chemin_dl:
		chemin_image = chemin_dl
	
	# on connecte les signaux
	script_get_ressource.music_downloaded.connect(music_downloaded)
	script_get_ressource.image_downloaded.connect(image_downloaded)
	script_get_ressource.end_download.connect(end_download)
	script_get_ressource.start_download.connect(start_download)
	script_get_ressource.musics_deleted.connect(musics_deleted)
	
	# on se connecte au player
	player = get_tree().get_first_node_in_group("player")
	creer_playlist.connect(player.creer_playlist_play)
	jouer_musique.connect(player.jouer_musique)
	
	player.playing.connect(playing)
	
	# ATTENTION la ligne suivante ne marche pas car tous les animation playing sont pris en compte, et pas seulement celui en local
	#noeud_animation_playing = get_tree().get_first_node_in_group("animation playing")
	noeud_animation_playing = $"animation playing"
	noeud_animation_download = $"animation download"
	
	# on affiche ou pas les différents indicateurs
	if script_get_ressource.est_image_de_musique_telecharge(id) or script_get_ressource.est_chemin_image_telecharge(chemin_image):
		image_downloaded(chemin_image)
	if script_get_ressource.est_musique_telecharge(id, Settings.get_setting("qualite")):
		music_downloaded(id)
	if player.get_node("../AudioStreamPlayer").has_stream_playback() and player.playlist_play[player.position_play] == id:
		playing(id)
	if FonctionsGlobal.id_current_download == id:
		start_download(id)

func _on_play_pressed() -> void:
	# position_playlist sert s'il y a plusieurs musiques identiques dans la playlist
	#jouer_musique.emit(id, position_playlist)
	if is_in_queue:
		jouer_musique.emit(position_playlist)
	else:
		creer_playlist.emit(position_playlist)

func music_downloaded(id_musique:int):
	if id == id_musique and not $"éléments/milieu/HBoxContainer/downloaded".visible:
		$"éléments/milieu/HBoxContainer/downloaded".visible = true

func image_downloaded(chemin_image_dl:String):
	if chemin_image == chemin_image_dl and not $"éléments/milieu/HBoxContainer/image downloaded".visible:
		$"éléments/milieu/HBoxContainer/image downloaded".visible = true

func end_download(id_musique:int):
	if id == id_musique:
		if $"éléments/milieu/HBoxContainer/dowloading".visible:
			$"éléments/milieu/HBoxContainer/dowloading".visible = false
		if not player.playlist_play[player.position_play] == id:
			set_process(false)

func start_download(id_musique:int):
	if id == id_musique:
		if not $"éléments/milieu/HBoxContainer/dowloading".visible:
			$"éléments/milieu/HBoxContainer/dowloading".visible = true
		set_process(true)
	else:
		end_download(id)

func musics_deleted(liste_id_musiques:Array, liste_chemins_images):
	if id in liste_id_musiques:
		if $"éléments/milieu/HBoxContainer/downloaded".visible:
			$"éléments/milieu/HBoxContainer/downloaded".visible = false
	if chemin_image in liste_chemins_images:
		# pour enlever l'icône, il faut à la fois que l'image de base soit supprimée, mais également la potentielle image téléchargée liée à cette musique (pas forcément la même que chemin_image)
		if $"éléments/milieu/HBoxContainer/image downloaded".visible:
			$"éléments/milieu/HBoxContainer/image downloaded".visible = false
			
func playing(id_musique:int):
	afficher_indicateur()
	if id == id_musique:
		if not $"éléments/milieu/HBoxContainer/titre".has_theme_color_override("font_color"):
			# change également la couleur du texte
			$"éléments/milieu/HBoxContainer/titre".add_theme_color_override("font_color", Color(0.004, 0.396, 0.929))
		set_process(true)
	else:
		if $"éléments/milieu/HBoxContainer/titre".has_theme_color_override("font_color"):
			# change également la couleur du texte
			$"éléments/milieu/HBoxContainer/titre".remove_theme_color_override("font_color")
			
		if not $"éléments/milieu/HBoxContainer/dowloading".visible:
			set_process(false)

func afficher_indicateur():
	# fonction qui affiche le numéro, l'animation playing ou le bouton play
	if focus:
		$"éléments/gauche/marges playing/playing".visible = false
		$"éléments/gauche/numéro".cacher()
		$"éléments/gauche/size play/play".afficher()
	else:
		if player.get_node("../AudioStreamPlayer").has_stream_playback() and player.playlist_play[player.position_play] == id:
			$"éléments/gauche/marges playing/playing".visible = true
			$"éléments/gauche/numéro".cacher()
			$"éléments/gauche/size play/play".cacher()
		elif afficher_numero:
			$"éléments/gauche/marges playing/playing".visible = false
			$"éléments/gauche/numéro".afficher()
			$"éléments/gauche/size play/play".cacher()
		else:
			$"éléments/gauche/marges playing/playing".visible = false
			$"éléments/gauche/numéro".cacher()
			$"éléments/gauche/size play/play".cacher()
	
func _process(delta: float) -> void:
	# on check le rafaichissement du playing
	if $"éléments/gauche/marges playing/playing".visible and get_window().has_focus():
		
		if Time.get_ticks_msec() - dernier_refresh_playing >= 30 and not player.get_node("../AudioStreamPlayer").stream_paused:
			# on passe à la frame suivante (si la musique est jouée)
			numero_frame_playing = (numero_frame_playing + 1) % 11
			$"éléments/gauche/marges playing/playing".texture = noeud_animation_playing.sprite_frames.get_frame_texture("default", numero_frame_playing)
			dernier_refresh_playing = Time.get_ticks_msec()
	
	# on check l'animation du downloading
	if $"éléments/milieu/HBoxContainer/dowloading".visible and get_window().has_focus():
		if Time.get_ticks_msec() - dernier_refresh_download >= 30:
			# on passe à la frame suivante
			numero_frame_download = (numero_frame_download + 1) % 30
			$"éléments/milieu/HBoxContainer/dowloading".texture = noeud_animation_download.sprite_frames.get_frame_texture("default", numero_frame_download)
			dernier_refresh_download = Time.get_ticks_msec()
			
func _process_old(_delta: float) -> void:
	# on check le rafaichissement du playing
	if player.get_node("../AudioStreamPlayer").has_stream_playback() and get_window().has_focus() and player.playlist_play[player.position_play] == id:
		# cette musique est jouée, on check le temps
		if not $"éléments/gauche/marges playing/playing".visible and not $"éléments/gauche/size play/play".visible:
			$"éléments/gauche/marges playing/playing".visible = true
		
		#if $"éléments/gauche/numéro".visible:
			#$"éléments/gauche/numéro".visible = false
		
		if not $"éléments/milieu/HBoxContainer/titre".has_theme_color_override("font_color"):
			# change également la couleur du texte
			$"éléments/milieu/HBoxContainer/titre".add_theme_color_override("font_color", Color(0.004, 0.396, 0.929))
		
		
		if Time.get_ticks_msec() - dernier_refresh_playing >= 30 and not player.get_node("../AudioStreamPlayer").stream_paused:
			# on passe à la frame suivante (si la musique est jouée)
			numero_frame_playing = (numero_frame_playing + 1) % 11
			$"éléments/gauche/marges playing/playing".texture = noeud_animation_playing.sprite_frames.get_frame_texture("default", numero_frame_playing)
			dernier_refresh_playing = Time.get_ticks_msec()
			
	else:
		if $"éléments/gauche/marges playing/playing".visible:
			$"éléments/gauche/marges playing/playing".visible = false
		
		# on remet la couleur du texte en blanc
		if $"éléments/milieu/HBoxContainer/titre".has_theme_color_override("font_color"):
			$"éléments/milieu/HBoxContainer/titre".remove_theme_color_override("font_color")
	
	# on affiche ou pas le numéro
	if not $"éléments/gauche/size play/play".visible and not $"éléments/gauche/marges playing/playing".visible:
		if not $"éléments/gauche/numéro".est_visible() and afficher_numero:
			$"éléments/gauche/numéro".afficher()
	elif $"éléments/gauche/numéro".est_visible():
		$"éléments/gauche/numéro".cacher()
	
	# on check le rafraichissement du download
	if FonctionsGlobal.id_current_download == id and not $"éléments/milieu/HBoxContainer/dowloading".visible:
		# on l'affiche car ça télécharge
		$"éléments/milieu/HBoxContainer/dowloading".visible = true
	if FonctionsGlobal.id_current_download != id and $"éléments/milieu/HBoxContainer/dowloading".visible:
		# fin du téléchargement, on retire le downloading
		$"éléments/milieu/HBoxContainer/dowloading".visible = false
	if script_get_ressource.est_musique_telecharge(id, Settings.get_setting("qualite")):
		if not $"éléments/milieu/HBoxContainer/downloaded".visible:
			$"éléments/milieu/HBoxContainer/downloaded".visible = true
	elif $"éléments/milieu/HBoxContainer/downloaded".visible:
		$"éléments/milieu/HBoxContainer/downloaded".visible = false
			
	if $"éléments/milieu/HBoxContainer/dowloading".visible and get_window().has_focus():
		if Time.get_ticks_msec() - dernier_refresh_download >= 30:
			# on passe à la frame suivante
			numero_frame_download = (numero_frame_download + 1) % 30
			$"éléments/milieu/HBoxContainer/dowloading".texture = noeud_animation_download.sprite_frames.get_frame_texture("default", numero_frame_download)
			dernier_refresh_download = Time.get_ticks_msec()

func _on_album_pressed() -> void:
	album_clicked.emit(id_album)


func _on_artiste_pressed() -> void:
	artiste_clicked.emit(id_artiste)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
		# on ouvre le sous menu
		var sous_menu = get_tree().get_first_node_in_group("sous menu")
		if is_in_queue:
			# pas d'options de téléchargement
			sous_menu.creer_sous_menu(self, [tr("ADD_TO_PLAYLIST"), tr("VIEW_ARTIST"), tr("VIEW_ALBUM")])
		else:
			var element
			# on change le bouton selon si la musique est téléchargée ou pas
			if script_get_ressource.est_musique_telecharge(id, Settings.get_setting("qualite")):
				element = tr("DELETE_FROM_DISK")
			else:
				element = tr("DOWNLOAD_MUSIC")
			if id_playlist == null:
				sous_menu.creer_sous_menu(self, [tr("ADD_TO_PLAYLIST"), tr("VIEW_ARTIST"), tr("VIEW_ALBUM"), element])
			else:
				sous_menu.creer_sous_menu(self, [tr("ADD_TO_PLAYLIST"), tr("REMOVE_FROM_PLAYLIST"), tr("VIEW_ARTIST"), tr("VIEW_ALBUM"), element])
	# déplacement
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var noeud_deplacement = get_tree().get_first_node_in_group("deplacement")
		if event.is_pressed():
			if id_playlist != null:
				# on lance le décalage
				noeud_deplacement.lancer_deplacement(id_playlist, position_playlist, $"éléments/masque/image")
		else:
			if id_playlist != null:
				noeud_deplacement.fin_deplacement()
				
func remove_from_playlist():
	if Client.is_locked:
		Notif.add_notif("NOT_ALLOWED")
		return
	Client.is_locked = true
	
	# on envoie la requête au serveur
	Client.noeud_appelant = self
	await Client.send(JSON.stringify({"type":"remove from playlist", "id_playlist":FonctionsGlobal.to_text(id_playlist), "position_playlist":FonctionsGlobal.to_text(position_playlist + 1)}))
	await remove_from_playlist_received
	
	# on supprime la musique du player
	get_tree().get_first_node_in_group("player").playlist.pop_at(position_playlist)
	# on change la position de toutes les musiques
	for musique in $"../".get_children():
		if musique is objet_musique and musique.position_playlist > position_playlist:
			musique.position_playlist -= 1
			musique.get_node("éléments/gauche/numéro").text = FonctionsGlobal.to_text(musique.position_playlist + 1)
	
	queue_free()
	Client.is_locked = false

func received(message_json, message_bytes):
	if not Client.check_keys(message_json, ["type", "resultat"]):
		push_error("clés invalides")
		Client.socket.close()
		Client.is_locked = false
		return
	if message_json["type"] == "remove from playlist":
		remove_from_playlist_received.emit(message_json, message_bytes)
		
func action(action_choisie):
	if action_choisie ==  tr("VIEW_ARTIST"):
		_on_artiste_pressed()
	elif action_choisie == tr("VIEW_ALBUM"):
		_on_album_pressed()
	elif action_choisie == tr("DOWNLOAD_MUSIC"):
		script_get_ressource.telecharger_musiques([id])
	elif action_choisie == tr("DELETE_FROM_DISK"):
		script_get_ressource.supprimer_musiques([id])
	elif action_choisie == tr("ADD_TO_PLAYLIST"):
		FonctionsGlobal.id_musique_ajout = id
	elif action_choisie == tr("REMOVE_FROM_PLAYLIST"):
		remove_from_playlist()
