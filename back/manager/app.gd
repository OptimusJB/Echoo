extends Control
var noeud_database
var noeud_artiste = load("res://back/manager/Artiste/Artiste.tscn")
var artistes_max_affichage = 20	# nombre max d'affichages avant le bouton "charger plus"
var artistes = []

func _ready() -> void:
	noeud_database = get_tree().get_nodes_in_group("database")[0]
	
func init():
	# fonction appelée par Manager, sert à charger les premiers trucs
	pass

func _charger_artiste_view(id_artiste):
	# fonction qui charge la page d'un artiste
	pass
	
func ajouter_artistes():
	var new_artiste
	var noeud_liste_artistes = get_tree().get_nodes_in_group("liste artistes")[0]
	var index_actuel
	var i=0
	var image_bytes
	while (i<artistes_max_affichage and (noeud_liste_artistes.get_child_count() - 1) < len(artistes[1])):
	#for i in range(min(artistes_max_affichage, len(artistes[1]))):
		index_actuel = noeud_liste_artistes.get_child_count() - 1
		new_artiste = noeud_artiste.instantiate()
		#print("requête : ", artistes[1][i])
		new_artiste.get_node("LineEdit").text = artistes[1][index_actuel]["nom"]
		new_artiste.get_node("LineEdit").id_artiste = artistes[1][index_actuel]["id"]
		new_artiste.get_node("systeme_image/charger artiste").charger_artiste.connect(_charger_artiste_view)
		
		# chargement de l'image
		var chemin_image = artistes[1][index_actuel]["image"]
		if not RessourceLoad.is_loaded(chemin_image):
			image_bytes = RessourceLoad.get_file_data(chemin_image)
			if image_bytes == "".to_utf8_buffer():
				Notif.add_notif("échec du chargement du fichier " + chemin_image)
			if image_bytes in ["".to_utf8_buffer(), "base".to_utf8_buffer()]:
				RessourceLoad.set_icone_base(chemin_image)
			else:
				RessourceLoad.charger_ressource(chemin_image, image_bytes)	# notif automatique
		if RessourceLoad.get_ressource(chemin_image) is ImageTexture or RessourceLoad.get_ressource(chemin_image) is Texture2D:	# Texture2D pour l'icône de base
			new_artiste.get_node("systeme_image/image").texture = RessourceLoad.get_ressource(chemin_image)
		else:
			RessourceLoad.set_icone_base(chemin_image)
			new_artiste.get_node("systeme_image/image").texture = RessourceLoad.icone_base
			push_error("la ressource d'id %d n'est pas du bon type" % chemin_image)
			Notif.add_notif("la ressource d'id %d n'est pas du bon type" % chemin_image)
		noeud_liste_artistes.add_child(new_artiste)
		noeud_liste_artistes.move_child(new_artiste, noeud_liste_artistes.get_child_count() - 2)
		i = i + 1
	# on check si tout est affiché
	#print(noeud_liste_artistes.get_child_count() - 1, len(artistes[1]))
	if noeud_liste_artistes.get_child_count() - 1 == len(artistes[1]):
		noeud_liste_artistes.get_node("charger plus").visible = false
	else:
		noeud_liste_artistes.get_node("charger plus").visible = true
		
func charger_artistes():
	# on récupère la recherche
	var recherche = get_tree().get_nodes_in_group("recherche_artiste")[0].text
	artistes = noeud_database.exec_sql("SELECT * FROM Artistes WHERE nom LIKE ?", ["%" + recherche + "%"])
	var noeud_liste_artistes = get_tree().get_nodes_in_group("liste artistes")[0]
	if not artistes[0]:
		# envoyer une notif
		Notif.add_notif("échec du chargement des artistes")
		return
	
	# suppression des artistes existants puis ajout nouveaux artistes
	for enfant in noeud_liste_artistes.get_children():
		# on vérifie si c'est pas le bouton
		if enfant is not Button:
			enfant.free()	# pas queue_free pour le test du get_child_count
	
	ajouter_artistes()

func _on_ajouter_artiste_pressed() -> void:
	# on ajoute l'artiste dans la base de données
	var database = get_tree().get_nodes_in_group("database")[0]
	var resultat = database.exec_sql("INSERT INTO Artistes(nom, image) VALUES('nouvel artiste', NULL)", [])
	if not resultat[0]:
		Notif.add_notif("échec de l'ajout de l'artiste")
		return
	
	# on fait une recherche automatique
	get_tree().get_nodes_in_group("recherche_artiste")[0].text = "nouvel artiste"
	charger_artistes()
