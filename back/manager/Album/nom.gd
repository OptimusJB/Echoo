extends LineEdit
var old_text = null

func update_nom(new_text: String) -> void:
	var id_album = $"../".id
	
	# en change le nom dans la requête
	if new_text == old_text:
		return
	old_text = new_text
	var database = get_tree().get_nodes_in_group("database")[0]
	var resultat = database.exec_sql("UPDATE Albums SET nom = ? WHERE id=?", [new_text, id_album])
	if resultat[0]:
		Notif.add_notif("nom de l'album changé")
	else:
		Notif.add_notif("échec du changement de nom de l'album")
	
	# on change le nom de l'album actuel si c'est le même et que c'est ouvert
	if int(get_tree().get_nodes_in_group("album actuel")[0].get_node("id album").text) == id_album and get_tree().get_nodes_in_group("parties")[2].visible:
		#print("changement album")
		get_tree().get_nodes_in_group("album actuel")[0].get_node("infos/nom").text = new_text
	
func _on_focus_exited() -> void:
	update_nom(text)

func _ready() -> void:
	old_text = text
