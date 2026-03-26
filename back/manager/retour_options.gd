extends Button

func _on_pressed() -> void:
	# on affiche la page principale
	get_tree().get_nodes_in_group("windows")[3].visible = false
	get_tree().get_nodes_in_group("windows")[1].visible = true
