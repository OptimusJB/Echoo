extends ScrollContainer
var noeud_header_album = preload("res://client/scènes/HeaderAlbum/HeaderAlbum.tscn")
var noeud_header_playlist = preload("res://client/scènes/HeaderPlaylist/HeaderPlaylist.tscn")
var noeud_legende = preload("res://client/scènes/Legende/Legende.tscn")

var script_get_ressource = preload("res://client/scènes/Accueil/easy_get_ressource.gd").new()
var noeud_enum:Node

var type_chargement=""

var album_infos
var playlist_infos

func charger_album(id_album:int, noeud_enumeration):
	# on envoie la recherche au serveur
	if Client.is_locked:
		Notif.add_notif("NOT_ALLOWED")
		return
	Client.is_locked = true

	noeud_enum = noeud_enumeration
	
	type_chargement = "album"
	# on ajoute le noeud dans la scène
	for enfant in noeud_enum.get_children():
		enfant.queue_free()
	noeud_enum.add_child(self)
	
	var noeud_player = get_tree().get_first_node_in_group("player") # pour créer la playlist
	noeud_player.playlist = []
	noeud_player.infos_musiques = {}
	noeud_player.nom_playlist = "Album"
	
	$"liste/texte loading".visible = true
	$"liste/téléchargement".visible = false
		
	Client.noeud_appelant = self
	Client.send(JSON.stringify({"type":"get musics of album", "id_album":FonctionsGlobal.to_text(id_album)}))
	
func charger_playlist(id_playlist, noeud_enumeration):
	if Client.is_locked:
		Notif.add_notif("NOT_ALLOWED")
		return
	Client.is_locked = true

	noeud_enum = noeud_enumeration
	
	type_chargement = "playlist"
	# on ajoute le noeud dans la scène
	for enfant in noeud_enum.get_children():
		enfant.queue_free()
	noeud_enum.add_child(self)
	
	var noeud_player = get_tree().get_first_node_in_group("player") # pour créer la playlist
	noeud_player.playlist = []
	noeud_player.infos_musiques = {}
	noeud_player.nom_playlist = "Playlist"
	
	$"liste/texte loading".visible = true
		
	Client.noeud_appelant = self
	Client.send(JSON.stringify({"type":"get musics of playlist", "id_playlist":FonctionsGlobal.to_text(id_playlist)}))
	
func received(message_json, _message_bytes):
	if not Client.check_keys(message_json, ["type", "resultat"]):
		push_error("clés invalides")
		Client.socket.close()
		Client.is_locked = false
		return
	
	var noeud_player = get_tree().get_first_node_in_group("player")
	if type_chargement == "album":
		noeud_player.nom_playlist = FonctionsGlobal.to_text(message_json["resultat"][0]["nom_album"])	# il y a forcément 1 élément
		# on ajoute le header
		var noeud_header = noeud_header_album.instantiate()
		noeud_header.id_album = FonctionsGlobal.to_int(message_json["resultat"][0]["id_album"])
		noeud_header.id_artiste = FonctionsGlobal.to_int(message_json["resultat"][0]["id_artiste"])
		noeud_header.get_node("éléments/marges/textes/nom").text = FonctionsGlobal.to_text(message_json["resultat"][0]["nom_album"])
		noeud_header.get_node("éléments/marges/textes/artiste").text = FonctionsGlobal.to_text(message_json["resultat"][0]["nom_artiste"])
		noeud_header.get_node("éléments/marges/textes/infos/texte infos").text = FonctionsGlobal.to_text_int(message_json["resultat"][0]["annee_album"]) + " ● " + FonctionsGlobal.to_text(message_json["resultat"][0]["genre_album"])
		noeud_header.get_node("éléments/masque/image").texture = await script_get_ressource.easy_get_image(message_json["resultat"][0]["image"])
		$liste.add_child(noeud_header)
		$liste.move_child(noeud_header, 1)	# pour le mettre avant les boutons de téléchargement
	
	elif type_chargement == "playlist":
		noeud_player.nom_playlist = FonctionsGlobal.to_text(message_json["resultat"][0]["nom_playlist"])
		# on ajoute le header
		var noeud_header = noeud_header_playlist.instantiate()
		noeud_header.id_playlist = FonctionsGlobal.to_int(message_json["resultat"][0]["id_playlist"])
		noeud_header.get_node("éléments/marges/textes/nom").text = FonctionsGlobal.to_text(message_json["resultat"][0]["nom_playlist"])
		noeud_header.get_node("éléments/marges/textes/pseudo").text = FonctionsGlobal.pseudo
		noeud_header.get_node("éléments/marges/textes/description").text = FonctionsGlobal.to_text(message_json["resultat"][0]["description_playlist"])
		noeud_header.get_node("éléments/masque/image").texture = await script_get_ressource.easy_get_image(message_json["resultat"][0]["image_playlist"])
		$liste.add_child(noeud_header)
		$liste.move_child(noeud_header, 1)	# pour le mettre avant les boutons de téléchargement
		
	# on ajoute la légende
	var new_noeud_legende = noeud_legende.instantiate()
	$liste.add_child(new_noeud_legende)
	
	# on s'arrête s'il n'y a rien
	if message_json["resultat"][0]["id"] == null:
		Client.is_locked = false
		$"liste/texte loading".visible = false
		return
			
	# on crée chaque noeud et on add_child
	var new_noeud
	var i = 0#len(noeud_player.playlist)	# pour position_playlist
	var compteur_download = 0	# nombre de musiques téléchargées
	
	for element in message_json["resultat"]:
		noeud_player.playlist.append(FonctionsGlobal.to_int(element["id"]))
		noeud_player.infos_musiques[FonctionsGlobal.to_int(element["id"])] = {"position":i, "nom":FonctionsGlobal.to_text(element["nom"]), "id_artiste":FonctionsGlobal.to_int(element["id_artiste"]), "nom_artiste":FonctionsGlobal.to_text(element["nom_artiste"]), "id_album":FonctionsGlobal.to_int(element["id_album"]), "nom_album":FonctionsGlobal.to_text(element["nom_album"]), "image":FonctionsGlobal.to_text(element["image"])}
		
		new_noeud = await script_get_ressource.creer_musique(FonctionsGlobal.to_int(element["id"]), i, FonctionsGlobal.to_text(element["nom"]), FonctionsGlobal.to_int(element["id_artiste"]), FonctionsGlobal.to_text(element["nom_artiste"]), FonctionsGlobal.to_int(element["id_album"]), FonctionsGlobal.to_text(element["nom_album"]), FonctionsGlobal.to_text(element["image"]), true)
		if new_noeud.est_telecharge:
			compteur_download += 1
		i += 1
		#new_noeud.get_node("éléments/gauche/numéro").cacher()
		
		$"liste".add_child(new_noeud)
		#$"liste".move_child(new_noeud, $"liste".get_child_count() - 2)
	
	# on cache les boutons download selon compteur download
	if compteur_download == i:
		# toutes les musiques sont téléchargées
		$"liste/téléchargement/boutons action/télécharger".visible = false
		$"liste/téléchargement/boutons action/supprimer".visible = true
	elif compteur_download == 0:
		# aucune musique n'est téléchargée
		$"liste/téléchargement/boutons action/télécharger".visible = true
		$"liste/téléchargement/boutons action/supprimer".visible = false
		
	$"liste/texte loading".visible = false
	$"liste/téléchargement".visible = true
	Client.is_locked = false


func _on_affichage_telechargement_toggled(toggled_on: bool) -> void:
	if toggled_on:
		$"liste/téléchargement/boutons action".visible = true
	else:
		$"liste/téléchargement/boutons action".visible = false


func _on_télécharger_pressed() -> void:
	if Client.is_locked:
		Notif.add_notif("NOT_ALLOWED")
		return
	Client.is_locked = true
	# on désélectionne le bouton nuage
	$"liste/téléchargement/size affichage/affichage".button_pressed = false
	
	await script_get_ressource.telecharger_musiques(get_tree().get_first_node_in_group("player").playlist)
	# on remplace le bouton
	$"liste/téléchargement/boutons action/télécharger".visible = false
	$"liste/téléchargement/boutons action/supprimer".visible = true
	Notif.add_notif("DOWNLOAD_END")
	Client.is_locked = false


func _on_supprimer_pressed() -> void:
	if Client.is_locked:
		Notif.add_notif("NOT_ALLOWED")
		return
	Client.is_locked = true
	
	# on désélectionne le bouton nuage
	$"liste/téléchargement/size affichage/affichage".button_pressed = false
	
	await script_get_ressource.supprimer_musiques(get_tree().get_first_node_in_group("player").playlist)
	# on remplace le bouton
	$"liste/téléchargement/boutons action/télécharger".visible = true
	$"liste/téléchargement/boutons action/supprimer".visible = false
	Notif.add_notif("REMOVE_END")
	Client.is_locked = false
