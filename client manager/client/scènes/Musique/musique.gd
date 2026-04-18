extends PanelContainer
var focus = false
var afficher_numero = true	# si false, le bouton n'apparaîtra pas quand on enlève la souris

var id:int
var position_playlist:int

signal jouer_musique

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
	if afficher_numero:
		$"éléments/gauche/numéro".afficher()

func _ready():
	# on se connecte au player
	var player = get_tree().get_first_node_in_group("player")
	jouer_musique.connect(player.creer_playlist_play)

func _on_play_pressed() -> void:
	# position_playlist sert s'il y a plusieurs musiques identiques dans la playlist
	#jouer_musique.emit(id, position_playlist)
	jouer_musique.emit(position_playlist)
