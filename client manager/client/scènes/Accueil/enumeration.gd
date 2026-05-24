extends PanelContainer
var scene_search_result = load("res://client/scènes/SearchResult/SearchResult.tscn")
var scene_music_view = load("res://client/scènes/MusicView/MusicView.tscn")
var scene_artiste_view = load("res://client/scènes/ArtisteView/ArtisteView.tscn")
var scene_settings_view = load("res://client/scènes/SettingsView/SettingsView.tscn")

func _on_rechercher_charger_recherche(recherche, only_dl) -> void:
	# on ajoute le search result et on lance sa fonction
	var new_scene = scene_search_result.instantiate()
	new_scene.charger_recherche(recherche, only_dl, self)
	# la scene recherche result va automatiquement s'ajouter quand il aura chargé

func _album_clicked(id_album:int):
	var new_scene = scene_music_view.instantiate()
	new_scene.charger_album(id_album, self)
	# la scene MusicView va automatiquement s'ajouter quand il aura chargé

func _artiste_clicked(id_artiste:int):
	var new_scene = scene_artiste_view.instantiate()
	new_scene.charger_artiste(id_artiste, self)
	# la scene ArtisteView va automatiquement s'ajouter quand il aura chargé

func _playlist_clicked(id_playlist:int):
	var new_scene = scene_music_view.instantiate()
	new_scene.charger_playlist(id_playlist, self)
	# la scene MusicView va automatiquement s'ajouter quand il aura chargé

func _settings_clicked():
	var new_scene = scene_settings_view.instantiate()
	new_scene.charger(self)
	# la scene va automatiquement s'ajouter quand il aura chargé
	
func clear_affichage():
	# on supprime tous les enfants
	for element in get_children():
		element.queue_free()
