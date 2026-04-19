extends Node
var noeud_musique = load("res://client/scènes/Musique/Musique.tscn")
var script_get_ressource = load("res://client/scènes/Accueil/easy_get_ressource.gd").new()

# variables globales
var pseudo = ""
var mdp = ""

var taille_envoi_fichier = 0.0
var id_serveur = 0


var start_music_selected = null # pour le shift sélection des musiques
#var musics_selected = [] # liste des musiques sélectionnées

func to_int(texte):
	# retourne l'élément en int, 0 si problème
	if texte is int:
		return texte
	if not texte:
		return 0
	if texte is float:
		return round(texte)
	if texte is String and texte.is_valid_int():
		return int(texte)
	return 0

func to_float(texte):
	# retourne l'élément en float, 0.0 si problème
	if texte is float:
		return texte
	if not texte:
		return 0.0
	if texte is String and texte.is_valid_float() or texte is int:
		return float(texte)
	return 0.0

func to_text(element):
	# retourne l'element en str, et "" si null
	if not element:
		return ""
	return str(element)

func to_text_int(element):
	# retourne l'élément sous forme d'entier en str
	# ex : 'truc' -> '0'
	#      '2025' -> '2025'
	return str(to_int(element))

func to_text_float(element):
	return str(to_float(element))

func secondes_to_text(temps:int):
	var minutes = int(float(temps)/60)
	var secondes = (temps % 60)
	return str(minutes) + ":" + str(secondes).pad_zeros(2)

func text_to_secondes(texte:String):
	var parties = texte.split(":")
	return int(parties[0]) * 60 + int(parties[1])

func creer_musique(id:int, position_playlist:int, nom:String, nom_artiste:String, nom_album:String, image:String, afficher_numero:bool) -> Node:
	var new_noeud = noeud_musique.instantiate()
	new_noeud.afficher_numero = false
	new_noeud.id = id
	new_noeud.position_playlist = position_playlist
	
	new_noeud.get_node("éléments/milieu/titre").text = nom
	new_noeud.get_node("éléments/milieu/artiste").text = nom_artiste
	new_noeud.get_node("éléments/album").text = nom_album
	
	new_noeud.get_node("éléments/masque/image").texture = await script_get_ressource.easy_get_image(image)
	return new_noeud
