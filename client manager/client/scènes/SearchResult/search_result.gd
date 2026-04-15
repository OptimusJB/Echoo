extends ScrollContainer
var noeud_musique = load("res://client/scènes/Musique/Musique.tscn")
var noeud_artiste = load("res://client/scènes/Artiste/Artiste.tscn")
var script_get_ressource = load("res://client/scènes/Accueil/easy_get_ressource.gd")

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
	
	Client.noeud_appelant = self
	Client.send(JSON.stringify({"type":"rechercher", "recherche":recherche_actuelle, "nb charges":nb_charges}))

func received(message_json, message_bytes):
	if not Client.check_keys(message_json, ["type", "resultat", "est fin"]):
		Client.socket.close()
		Client.is_locked = false
		return
	
	# ne pas mettre de suppression
	# on crée chaque noeud et on add_child
	#print("reçu : ", message_json)
	#print("reçu")
	var new_noeud
	for element in message_json["resultat"]:
		if element["type_table"] == "musique":
			# l'élément est une musique
			new_noeud = noeud_musique.instantiate()
			new_noeud.afficher_numero = false
			new_noeud.get_node("éléments/gauche/numéro").visible = false
			new_noeud.get_node("éléments/milieu/titre").text = FonctionsGlobal.to_text(element["nom"])
			new_noeud.get_node("éléments/milieu/artiste").text = FonctionsGlobal.to_text(element["nom_artiste"])
			new_noeud.get_node("éléments/album").text = FonctionsGlobal.to_text(element["nom_album"])
			
			new_noeud.get_node("éléments/image").texture = await script_get_ressource.new().easy_get_image(element["image"])
			
			$"liste".add_child(new_noeud)
			$"liste".move_child(new_noeud, $"liste".get_child_count() - 2)
			nb_charges += 1
	
	if first_charge:
		# on ajoute la recherche dans la scène
		for enfant in noeud_enum.get_children():
			enfant.queue_free()
		noeud_enum.add_child(self)
		first_charge = false
	
	# on cache / montre charger plus selon si c'est la fin ou pas
	if message_json["est fin"]:
		$"liste/charger plus".visible = false
	else:
		$"liste/charger plus".visible = true
		
	Client.is_locked = false


func _on_charger_plus_pressed() -> void:
	charger_recherche()
