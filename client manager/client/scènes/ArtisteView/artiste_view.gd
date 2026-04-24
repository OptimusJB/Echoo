extends ScrollContainer

var noeud_album = preload("res://client/scènes/Album/Album.tscn")
var script_get_ressource = preload("res://client/scènes/Accueil/easy_get_ressource.gd").new()

var noeud_enum:Node

func charger_artiste(id_artiste:int, noeud_enumeration):
	# on envoie la recherche au serveur
	if Client.is_locked:
		# un autre recherche est probablement en cours
		# dans le doute on ne met pas la notif
		#Notif.add_notif("NOT_ALLOWED")
		return
	Client.is_locked = true

	noeud_enum = noeud_enumeration
	
	# on add_child la scène
	for enfant in noeud_enum.get_children():
		enfant.queue_free()
	noeud_enum.add_child(self)
	
	#var noeud_player = get_tree().get_first_node_in_group("player") # pour créer la playlist
	
	$"éléments/texte loading".visible = true
	$"éléments/fond header".visible = false
	$"éléments/texte albums".visible = false
	
	Client.noeud_appelant = self
	Client.send(JSON.stringify({"type":"get artiste infos", "id_artiste":id_artiste}))

func received(message_json, _message_bytes):
	if not Client.check_keys(message_json, ["type", "resultat"]):
		push_error("clés invalides")
		Client.socket.close()
		Client.is_locked = false
		return
	
	# on met les infos sur le header (il y a au moins 1 résultat)
	$"éléments/fond header/header/nom".text = FonctionsGlobal.to_text(message_json["resultat"][0]["nom_artiste"])
	$"éléments/fond header/header/masque/image".texture = await script_get_ressource.easy_get_image(message_json["resultat"][0]["image_artiste"])
	
	# on crée et ajoute les albums
	var new_noeud
	for element in message_json["resultat"]:
		new_noeud = noeud_album.instantiate()
		new_noeud.id = FonctionsGlobal.to_int(element["id_album"])
		new_noeud.get_node("marges/éléments/nom").text = FonctionsGlobal.to_text(element["nom_album"])
		new_noeud.get_node("marges/éléments/infos").text = FonctionsGlobal.to_text_int(element["annee"])
		new_noeud.get_node("marges/éléments/cache/image").texture =  await script_get_ressource.easy_get_image(FonctionsGlobal.to_text(element["image_album"]))
		
		$"éléments/albums".add_child(new_noeud)
		#$"liste".move_child(new_noeud, $"liste".get_child_count() - 2)
		
	$"éléments/texte loading".visible = false
	$"éléments/fond header".visible = true
	$"éléments/texte albums".visible = true
	Client.is_locked = false
