extends PanelContainer
var scene_search_result = load("res://client/scènes/SearchResult/SearchResult.tscn")
var scene_music_view = load("res://client/scènes/MusicView/MusicView.tscn")

func _on_rechercher_charger_recherche(recherche) -> void:
	# on ajoute le search result et on lance sa fonction
	var new_scene = scene_search_result.instantiate()
	new_scene.charger_recherche(recherche, self)
	# la scene recherche result va automatiquement s'ajouter quand il aura chargé

func _album_clicked(id_album:int):
	var new_scene = scene_music_view.instantiate()
	new_scene.charger_album(id_album, self)
	# la scene recherche result va automatiquement s'ajouter quand il aura chargé
