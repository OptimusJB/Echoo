extends PanelContainer
var script_get_ressource = preload("res://client/scènes/Accueil/easy_get_ressource.gd").new()
var a_charger = true
var a_update = false

var current_musics = []

func charger_file():
	
	if not visible:
		# on chargera plus tard
		a_charger = true
		return
		
	# on supprime tous les éléments déjà présents
	for element in $"marges/éléments/scroll/listes musiques".get_children():
		element.queue_free()
	
	# on affiche avec le texte de chargement
	$"marges/éléments/file d'attente".text = "LOADING"
	#visible = true
	
	# on récupère la liste des musiques
	var player = get_tree().get_first_node_in_group("player")
	var position_musique = player.position_play
	var liste_musiques = player.playlist_play
	
	if position_musique == -1:
		# pas de musique jouée
		push_error("pas de musique jouée")
		return
	
	current_musics = player.playlist_play.duplicate()
	print("chargement file d'attente")
	
	var new_element
	for i in range(len(liste_musiques)):
		#new_element = await FonctionsGlobal.creer_musique(liste_musiques[i], player.infos_musiques_play[liste_musiques[i]]["position"], player.infos_musiques_play[liste_musiques[i]]["nom"], player.infos_musiques_play[liste_musiques[i]]["id_artiste"], player.infos_musiques_play[liste_musiques[i]]["nom_artiste"], player.infos_musiques_play[liste_musiques[i]]["id_album"], player.infos_musiques_play[liste_musiques[i]]["nom_album"], player.infos_musiques_play[liste_musiques[i]]["image"], false)
		new_element = await script_get_ressource.creer_musique(liste_musiques[i], i, player.infos_musiques_play[liste_musiques[i]]["nom"], player.infos_musiques_play[liste_musiques[i]]["id_artiste"], player.infos_musiques_play[liste_musiques[i]]["nom_artiste"], player.infos_musiques_play[liste_musiques[i]]["id_album"], player.infos_musiques_play[liste_musiques[i]]["nom_album"], player.infos_musiques_play[liste_musiques[i]]["image"], false)
		new_element.is_in_queue = true
		new_element.get_node("éléments/gauche/numéro").cacher()
		new_element.get_node("éléments/album").cacher()
		
		if i < position_musique:
			new_element.visible = false
		$"marges/éléments/scroll/listes musiques".add_child(new_element)
	
	# on met le titrede la playlist / album
	$"marges/éléments/file d'attente".text = tr("QUEUE") + " : " + str(player.nom_playlist)
	a_charger = false


func update():
	# appelé par le player quand la file d'attente doit être changée sans tout recharger
	if not visible:
		a_update = true
		return
	
	var noeud_player = get_tree().get_first_node_in_group("player")
	if current_musics != noeud_player.playlist_play:
		# on charge
		charger_file()
		a_update = false
		return
		
	var noeud_liste_musiques = $"marges/éléments/scroll/listes musiques"
	for i in range(noeud_liste_musiques.get_child_count()):
		if i < noeud_player.position_play:
			noeud_liste_musiques.get_child(i).visible = false
		else:
			noeud_liste_musiques.get_child(i).visible = true
	
	# on met à jour le titre au cas où le titre de la même playlist à changé
	$"marges/éléments/file d'attente".text = tr("QUEUE") + " : " + str(noeud_player.nom_playlist)
	a_update = false

func afficher():
	visible = true
	if a_charger:
		charger_file()
	elif a_update:
		update()
	a_charger = false
	a_update = false

func cacher():
	visible = false
