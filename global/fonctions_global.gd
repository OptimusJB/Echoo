extends Node

var start_music_selected = null # pour le shift sélection des musiques
#var musics_selected = [] # liste des musiques sélectionnées

func to_int(texte):
	# retourne l'élément en int, 0 si problème
	if texte is int:
		return texte
	if not texte:
		return 0
	if texte is String and texte.is_valid_int():
		return int(texte)
	return 0
	

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
