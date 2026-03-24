extends Button

func _on_pressed() -> void:
	# on affiche la page de gestion des utilisateurs
	get_tree().get_nodes_in_group("windows")[1].visible = false
	get_tree().get_nodes_in_group("windows")[2].visible = true
