extends ScrollContainer
var noeud_artiste = preload("res://client/scènes/Artiste/Artiste.tscn")
var script_get_ressource = preload("res://client/scènes/Accueil/easy_get_ressource.gd").new()

var noeud_enum:Node
var recherche_actuelle

var nb_charges = 0
var first_charge = true

func charger_recherche(recherche = null, noeud_enumeration = null):
	# on envoie la recherche au serveur
	if Client.is_locked:
		# un autre recherche est probablement en cours
		# dans le doute on ne met pas la notif
		#Notif.add_notif("NOT_ALLOWED")
		return
	Client.is_locked = true
	
	if recherche != null:
		recherche_actuelle = recherche

	if noeud_enumeration:
		noeud_enum = noeud_enumeration
	
	if first_charge:
		# on ajoute la recherche dans la scène
		for enfant in noeud_enum.get_children():
			enfant.queue_free()
		noeud_enum.add_child(self)
		
		var noeud_player = get_tree().get_first_node_in_group("player") # pour créer la playlist
		noeud_player.playlist = []
		noeud_player.infos_musiques = {}
		noeud_player.nom_playlist = "recherche"
	
		first_charge = false
	$"liste/charger plus".visible = false
	$"liste/resultat recherche".text = "LOADING"
		
	Client.noeud_appelant = self
	Client.send(JSON.stringify({"type":"rechercher", "recherche":recherche_actuelle, "nb charges":nb_charges}))

func received(message_json, _message_bytes):
	if not Client.check_keys(message_json, ["type", "resultat", "est fin"]):
		push_error("clés invalides")
		Client.socket.close()
		Client.is_locked = false
		return
	
	# ne pas mettre de suppression
	# on crée chaque noeud et on add_child
	#print("reçu : ", message_json)
	#print("reçu")
	var new_noeud
	var noeud_player = get_tree().get_first_node_in_group("player") # pour créer la playlist
	var i = len(noeud_player.playlist)	# pour position_playlist
	
	for element in message_json["resultat"]:
		if element["type_table"] == "musique":
			# l'élément est une musique
			noeud_player.playlist.append(FonctionsGlobal.to_int(element["id"]))
			noeud_player.infos_musiques[FonctionsGlobal.to_int(element["id"])] = {"position":i, "nom":FonctionsGlobal.to_text(element["nom"]), "id_artiste":FonctionsGlobal.to_int(element["id_artiste"]), "nom_artiste":FonctionsGlobal.to_text(element["nom_artiste"]), "id_album":FonctionsGlobal.to_int(element["id_album"]), "nom_album":FonctionsGlobal.to_text(element["nom_album"]), "image":FonctionsGlobal.to_text(element["image"])}
			
			new_noeud = await FonctionsGlobal.creer_musique(FonctionsGlobal.to_int(element["id"]), i, FonctionsGlobal.to_text(element["nom"]), FonctionsGlobal.to_int(element["id_artiste"]), FonctionsGlobal.to_text(element["nom_artiste"]), FonctionsGlobal.to_int(element["id_album"]), FonctionsGlobal.to_text(element["nom_album"]), FonctionsGlobal.to_text(element["image"]), false)
			i += 1
			new_noeud.get_node("éléments/gauche/numéro").cacher()
			
			$"liste".add_child(new_noeud)
			$"liste".move_child(new_noeud, $"liste".get_child_count() - 2)
			nb_charges += 1
		
		elif element["type_table"] == "artiste":
			# l'élément est un artiste
			new_noeud = noeud_artiste.instantiate()
			new_noeud.id = FonctionsGlobal.to_int(element["id"])
			new_noeud.get_node("éléments/nom").text = FonctionsGlobal.to_text(element["nom"])
			new_noeud.get_node("éléments/masque/image").texture = await script_get_ressource.easy_get_image(element["image"])
			
			$"liste".add_child(new_noeud)
			$"liste".move_child(new_noeud, $"liste".get_child_count() - 2)
			nb_charges += 1
		else:
			push_error("problème type_table")
			return
	
	# on cache / montre charger plus selon si c'est la fin ou pas
	if message_json["est fin"]:
		$"liste/charger plus".visible = false
	else:
		$"liste/charger plus".visible = true
		
	$"liste/resultat recherche".text = "SEARCH_RESULTS"
	Client.is_locked = false


func _on_charger_plus_pressed() -> void:
	charger_recherche()
