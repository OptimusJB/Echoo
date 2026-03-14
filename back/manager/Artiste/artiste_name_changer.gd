extends LineEdit
var id_artiste
var old_text = null

func update_nom(new_text: String) -> void:
	# en change le nom dans la requête
	if new_text == old_text:
		return
	old_text = new_text
	var database = get_tree().get_nodes_in_group("database")[0]
	var resultat = database.exec_sql("UPDATE Artistes SET nom = ? WHERE id=?", [new_text, id_artiste])
	if resultat[0]:
		Notif.add_notif("nom de l'artiste changé")
	else:
		Notif.add_notif("échec du changement de nom de l'artiste")

func _on_focus_exited() -> void:
	update_nom(text)

func _ready() -> void:
	old_text = text
