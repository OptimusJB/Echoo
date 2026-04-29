extends PanelContainer
var script_get_ressoure = preload("res://client/scènes/Accueil/easy_get_ressource.gd").new()
var player

var focus = false
var afficher_numero = true	# si false, le bouton n'apparaîtra pas quand on enlève la souris

var id:int
var id_artiste:int
var id_album:int
var position_playlist:int

var dernier_refresh_playing = Time.get_ticks_msec()	# pour l'animation playing
var numero_frame_playing = 0
var noeud_animation_playing

var dernier_refresh_download = Time.get_ticks_msec() # pour l'animation download
var numero_frame_download = 0
var noeud_animation_download

var is_in_queue	= false	# mettre à true si jamais la musique est dans la file d'attente

var est_telecharge = false

signal jouer_musique
signal creer_playlist

signal album_clicked
signal artiste_clicked

func _on_mouse_entered() -> void:
	focus = true
	# on change la couleur du fond
	var stylebox = get_theme_stylebox("panel").duplicate()
	stylebox.bg_color = Color(0.279, 0.279, 0.279)
	add_theme_stylebox_override("panel", stylebox)
	
	# on affiche le play et on cache le numéro
	$"éléments/gauche/numéro".cacher()
	$"éléments/gauche/size play/play".afficher()

func _on_mouse_exited() -> void:
	focus = false
	# on change la couleur du fond
	var stylebox = get_theme_stylebox("panel").duplicate()
	stylebox.bg_color = Color(0.278, 0.278, 0.278, 0.0)
	add_theme_stylebox_override("panel", stylebox)
	
	# on affiche le numéro (si affiher_numero) et on cache le play
	$"éléments/gauche/size play/play".cacher()
	#if afficher_numero:
		#$"éléments/gauche/numéro".afficher()

func _ready():
	# on se connecte au player
	player = get_tree().get_first_node_in_group("player")
	creer_playlist.connect(player.creer_playlist_play)
	jouer_musique.connect(player.jouer_musique)
	
	# ATTENTION la ligne suivante ne marche pas car tous les animation playing sont pris en compte, et pas seulement celui en local
	#noeud_animation_playing = get_tree().get_first_node_in_group("animation playing")
	noeud_animation_playing = $"animation playing"
	noeud_animation_download = $"animation download"

func _on_play_pressed() -> void:
	# position_playlist sert s'il y a plusieurs musiques identiques dans la playlist
	#jouer_musique.emit(id, position_playlist)
	if is_in_queue:
		jouer_musique.emit(position_playlist)
	else:
		creer_playlist.emit(position_playlist)

func _process(delta: float) -> void:
	# on check le rafaichissement du playing
	if player.get_node("../AudioStreamPlayer").has_stream_playback():	# on change l'animation seulement si focus:
		if get_window().has_focus():
			if player.playlist_play[player.position_play] == id:
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
					numero_frame_playing = (numero_frame_playing + 1) % 150
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
			#print("afficher")
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
	if script_get_ressoure.est_musique_telecharge(id, Settings.get_setting("qualite")):
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
			sous_menu.creer_sous_menu(self, ["ajouter à la playlist", tr("VIEW_ARTIST"), "accéder à l'album"])
		else:
			var element
			# on change le bouton selon si la musique est téléchargée ou pas
			if script_get_ressoure.est_musique_telecharge(id, Settings.get_setting("qualite")):
				element = tr("DELETE_FROM_DISK")
			else:
				element = tr("DOWNLOAD_MUSIC")
			sous_menu.creer_sous_menu(self, [tr("ADD_TO_PLAYLIST"),  tr("VIEW_ARTIST"), tr("VIEW_ALBUM"), element])

func action(action_choisie):
	if action_choisie ==  tr("VIEW_ARTIST"):
		_on_artiste_pressed()
	elif action_choisie == tr("VIEW_ALBUM"):
		_on_album_pressed()
	elif action_choisie == tr("DOWNLOAD_MUSIC"):
		script_get_ressoure.telecharger_musiques([id])
	elif action_choisie == tr("DELETE_FROM_DISK"):
		script_get_ressoure.supprimer_musiques([id])
