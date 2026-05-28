extends LineEdit

var old_text = null

func update_nom(new_text: String) -> void:
	var id_musique = $"../../".id
	
	# en change le nom dans la requête
	if new_text == old_text:
		return
	old_text = new_text
	var database = get_tree().get_nodes_in_group("database")[0]
	var resultat = database.exec_sql("UPDATE Musiques SET nom = ? WHERE id=?", [new_text, id_musique])
	if resultat[0]:
		Notif.add_notif("nom de la musique changé")
	else:
		Notif.add_notif("échec du changement de nom de la musique")
	
func _on_focus_exited() -> void:
	update_nom(text)

func _ready() -> void:
	old_text = text
