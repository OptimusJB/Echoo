extends PanelContainer
var player

var focus = false
var afficher_numero = true	# si false, le bouton n'apparaîtra pas quand on enlève la souris

var id:int
var id_artiste:int
var id_album:int
var position_playlist:int

var dernier_refresh = Time.get_ticks_msec()	# pour l'animation playing
var numero_frame = 0
var noeud_animation

var is_in_queue	= false	# mettre à true si jamais la musique est dans la file d'attente

signal jouer_musique
signal creer_playlist

signal album_clicked

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
	#noeud_animation = get_tree().get_first_node_in_group("animation playing")
	noeud_animation = $"animation playing"

func _on_play_pressed() -> void:
	# position_playlist sert s'il y a plusieurs musiques identiques dans la playlist
	#jouer_musique.emit(id, position_playlist)
	if is_in_queue:
		jouer_musique.emit(position_playlist)
	else:
		creer_playlist.emit(position_playlist)

func _process(delta: float) -> void:
	# on check le rafaichissement
	if player.get_node("../AudioStreamPlayer").has_stream_playback():	# on change l'animation seulement si focus:
		if not get_window().has_focus():
			return
		if player.playlist_play[player.position_play] == id:
			# cette musique est jouée, on check le temps
			if not $"éléments/gauche/marges playing/playing".visible and not $"éléments/gauche/size play/play".visible:
				$"éléments/gauche/marges playing/playing".visible = true
			
			#if $"éléments/gauche/numéro".visible:
				#$"éléments/gauche/numéro".visible = false
			
			if not $"éléments/milieu/titre".has_theme_color_override("font_color"):
				# change également la couleur du texte
				$"éléments/milieu/titre".add_theme_color_override("font_color", Color(0.004, 0.396, 0.929))
			
			
			if Time.get_ticks_msec() - dernier_refresh >= 30 and not player.get_node("../AudioStreamPlayer").stream_paused:
				# on passe à la frame suivante (si la musique est jouée)
				numero_frame = (numero_frame + 1) % 150
				$"éléments/gauche/marges playing/playing".texture = noeud_animation.sprite_frames.get_frame_texture("default", numero_frame)
				dernier_refresh = Time.get_ticks_msec()
			
	else:
		if $"éléments/gauche/marges playing/playing".visible:
			$"éléments/gauche/marges playing/playing".visible = false
		
		# on remet la couleur du texte en blanc
		if $"éléments/milieu/titre".has_theme_color_override("font_color"):
			$"éléments/milieu/titre".remove_theme_color_override("font_color")
	
	# on affiche ou pas le numéro
	if not $"éléments/gauche/size play/play".visible and not $"éléments/gauche/marges playing/playing".visible:
		if not $"éléments/gauche/numéro".est_visible() and afficher_numero:
			#print("afficher")
			$"éléments/gauche/numéro".afficher()
	elif $"éléments/gauche/numéro".est_visible():
		$"éléments/gauche/numéro".cacher()

func _on_album_pressed() -> void:
	album_clicked.emit(id_album)
