extends Control
var noeud_database
var noeud_artiste = load("res://back/manager/Artiste/Artiste.tscn")
var noeud_album = load("res://back/manager/Album/Album.tscn")
var noeud_musique = load("res://back/manager/musique/musique.tscn")
var artistes_max_affichage = 20	# nombre max d'affichages avant le bouton "charger plus"
var artistes = []

func _ready() -> void:
	noeud_database = get_tree().get_nodes_in_group("database")[0]
	
func init():
	# fonction appelée par Manager, sert à charger les premiers trucs
	pass
	
func _charger_album_view(id_album):
	# fonction qui charge la page d'un album
	var noeud_album_actuel = get_tree().get_nodes_in_group("album actuel")[0]
	
	# on récupère les infos de l'artiste
	var resultat = noeud_database.exec_sql("SELECT nom, annee, image, genre FROM Albums WHERE id=?", [id_album])
	if not resultat[0]:
		Notif.add_notif("éche de la récupération des infos de l'album")
		return
	if len(resultat[1]) != 1:
		push_error("nombre anormal de résultats")
		return
		
	var nom_album = resultat[1][0]["nom"]
	var chemin_image = resultat[1][0]["image"]
	var annee_album = resultat[1][0]["annee"]
	var genre_album = resultat[1][0]["genre"]
	noeud_album_actuel.get_node("image album").texture = RessourceLoad.easy_get_image(chemin_image)
	noeud_album_actuel.get_node("infos/nom").text = FonctionsGlobal.to_text(nom_album)
	#print("base : %s, après:%s" % [FonctionsGlobal.to_text(annee_album), FonctionsGlobal.to_text_int(annee_album)])
	noeud_album_actuel.get_node("infos/annee").text = FonctionsGlobal.to_text_int(annee_album)
	noeud_album_actuel.get_node("infos/genre").text = FonctionsGlobal.to_text(genre_album)
	noeud_album_actuel.get_node("id album").text = FonctionsGlobal.to_text(id_album)
	
	var noeud_liste_musiques = get_tree().get_nodes_in_group("liste musiques")[0]
	# on supprime les potentiels anciens albums
	for enfant in noeud_liste_musiques.get_children():
		enfant.queue_free()
	
	# on charge les différents albums
	resultat = noeud_database.exec_sql("SELECT Musiques.id AS id_musique, Musiques.nom AS nom_musique, Musiques.min, Musiques.moy, Musiques.max, Musiques.position_album FROM Musiques JOIN Albums ON Albums.id = Musiques.id_album WHERE Albums.id=?", [id_album])
	if not resultat[0]:
		Notif.add_notif("échec de la récupération des musiques")
	else:
		# on ajoute toutes les musiques
		var new_musique
		for musique in resultat[1]:
			new_musique = noeud_musique.instantiate()
			new_musique.id = musique["id_musique"]
			new_musique.get_node("infos/titre").text = FonctionsGlobal.to_text(musique["nom_musique"])
			new_musique.get_node("infos/fichiers/fichier min").text = FonctionsGlobal.to_text(musique["min"])
			new_musique.get_node("infos/fichiers/fichier moy").text = FonctionsGlobal.to_text(musique["moy"])
			new_musique.get_node("infos/fichiers/fichier max").text = FonctionsGlobal.to_text(musique["max"])
			
			noeud_liste_musiques.add_child(new_musique)
			
	get_tree().get_nodes_in_group("parties")[2].visible = true
	
func _charger_artiste_view(id_artiste):
	# fonction qui charge la page d'un artiste
	var noeud_artiste_actuel = get_tree().get_nodes_in_group("artiste actuel")[0]
	
	# on récupère les infos de l'artiste
	var resultat = noeud_database.exec_sql("SELECT nom, image FROM Artistes WHERE id=?", [id_artiste])
	if not resultat[0]:
		Notif.add_notif("éche de la récupération des infos de l'artiste")
		return
	if len(resultat[1]) != 1:
		push_error("nombre anormal de résultats")
		return
		
	var nom_artiste = resultat[1][0]["nom"]
	var chemin_image = resultat[1][0]["image"]
	noeud_artiste_actuel.get_node("image artiste").texture = RessourceLoad.easy_get_image(chemin_image)
	noeud_artiste_actuel.get_node("nom artiste").text = FonctionsGlobal.to_text(nom_artiste)
	noeud_artiste_actuel.get_node("id artiste").text = FonctionsGlobal.to_text(id_artiste)
	
	#var noeud_liste_albums = noeud_artiste_actuel.get_node("../ScrollContainer/liste albums")
	var noeud_liste_albums = get_tree().get_nodes_in_group("liste albums")[0]
	# on supprime les potentiels anciens albums
	for enfant in noeud_liste_albums.get_children():
		enfant.queue_free()
	
	# on charge les différents albums
	resultat = noeud_database.exec_sql("SELECT Albums.id AS id_album, Albums.nom AS nom_album, Albums.image AS image_album FROM Albums JOIN Artistes ON Artistes.id = Albums.id_artiste WHERE Artistes.id=?", [id_artiste])
	if not resultat[0]:
		Notif.add_notif("échec de la récupération des albums")
	else:
		# on ajoute tous les albums
		var new_album
		for album in resultat[1]:
			new_album = noeud_album.instantiate()
			new_album.id = album["id_album"]
			new_album.get_node("nom").text = FonctionsGlobal.to_text(album["nom_album"])
			new_album.get_node("systeme_image/image").texture = RessourceLoad.easy_get_image(album["image_album"])
			
			noeud_liste_albums.add_child(new_album)
			new_album.get_node("systeme_image/charger album").charger_album.connect(_charger_album_view)
			
	get_tree().get_nodes_in_group("parties")[1].get_node("../").visible = true

func ajouter_artistes():
	var new_artiste
	var noeud_liste_artistes = get_tree().get_nodes_in_group("liste artistes")[0]
	var index_actuel
	var i=0
	while (i<artistes_max_affichage and (noeud_liste_artistes.get_child_count() - 1) < len(artistes[1])):
	#for i in range(min(artistes_max_affichage, len(artistes[1]))):
		index_actuel = noeud_liste_artistes.get_child_count() - 1
		new_artiste = noeud_artiste.instantiate()
		#print("requête : ", artistes[1][i])
		new_artiste.get_node("LineEdit").text = FonctionsGlobal.to_text(artistes[1][index_actuel]["nom"])
		new_artiste.get_node("LineEdit").id_artiste = artistes[1][index_actuel]["id"]
		new_artiste.get_node("systeme_image/charger artiste").charger_artiste.connect(_charger_artiste_view)
		
		# chargement de l'image
		var chemin_image = artistes[1][index_actuel]["image"]
		new_artiste.get_node("systeme_image/image").texture = RessourceLoad.easy_get_image(chemin_image)
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
	var resultat = database.exec_sql("INSERT INTO Artistes(nom) VALUES('nouvel artiste')", [])
	if not resultat[0]:
		Notif.add_notif("échec de l'ajout de l'artiste")
		return
	
	# on fait une recherche automatique
	get_tree().get_nodes_in_group("recherche_artiste")[0].text = "nouvel artiste"
	charger_artistes()

func _on_ajouter_album_pressed() -> void:
	# on récupère l'id de l'artiste actuellement ouvert
	var id_artiste_actuel = int(get_tree().get_nodes_in_group("artiste actuel")[0].get_node("id artiste").text)
	# on ajoute l'album dans la base de données
	var database = get_tree().get_nodes_in_group("database")[0]
	var resultat = database.exec_sql("INSERT INTO Albums(id_artiste, nom) VALUES(?, 'nouvel album')", [id_artiste_actuel])
	if not resultat[0]:
		Notif.add_notif("échec de l'ajout de l'album")
		return
	
	# on ne connait pas l'id du nouvel album, donc on recharge tout
	_charger_artiste_view(id_artiste_actuel)
