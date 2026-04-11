extends Button

func _on_pressed() -> void:
	var noeud_database = get_tree().get_nodes_in_group("database")[0]
	var resultat = noeud_database.exec_sql("UPDATE Utilisateurs set banni=1 WHERE id=?", [$"../../".id])
	if not resultat[0]:
		Notif.add_notif("échec du bannissement")
		return
	
	$"../../".set_banni()
