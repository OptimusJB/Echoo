extends PanelContainer
var scene_search_result = load("res://client/scènes/SearchResult/SearchResult.tscn")

func _on_rechercher_charger_recherche(recherche) -> void:
	# on ajoute le search result et on lance sa fonction
	var new_scene = scene_search_result.instantiate()
	new_scene.charger_recherche(self, recherche)
	# la scene recherche result va automatiquement s'ajouter quand il aura chargé
