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
	
	# on change le nom de l'artiste actuel si c'est le même et que c'est ouvert
	if int(get_tree().get_nodes_in_group("artiste actuel")[0].get_node("id artiste").text) == id_artiste and get_tree().get_nodes_in_group("parties")[1].get_node("../").visible:
		get_tree().get_nodes_in_group("artiste actuel")[0].get_node("nom artiste").text = new_text

func _on_focus_exited() -> void:
	update_nom(text)

func _ready() -> void:
	old_text = text
