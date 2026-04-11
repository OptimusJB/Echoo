extends Control

func add_notif(texte_notif):
	var liste = get_tree().get_nodes_in_group("notifs")[0]
	var preset = get_tree().get_nodes_in_group("notif_preset")[0]
	var new_notif = preset.duplicate()
	new_notif.get_node("texte").text = texte_notif
	liste.add_child(new_notif)
	new_notif.visible = true	# au cas où ça duplique aussi la visibilité
	new_notif.get_node("temps_affichage").start()
