extends LineEdit
var old_text = null

func update_genre(new_text: String) -> void:
	# en change l'année dans la requête
	if new_text == old_text:
		return
	old_text = new_text
	var id_album = FonctionsGlobal.to_int(get_node("../../id album").text)
	var database = get_tree().get_nodes_in_group("database")[0]
	var resultat = database.exec_sql("UPDATE Albums SET genre = ? WHERE id=?", [new_text, id_album])
	if resultat[0]:
		Notif.add_notif("genre de l'album changé")
	else:
		Notif.add_notif("échec du changement du genre de l'album")

func _on_focus_exited() -> void:
	update_genre(text)
