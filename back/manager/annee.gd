extends LineEdit
var old_text = null

func update_annee(new_text: String) -> void:
	# en change l'année dans la requête
	if new_text == old_text:
		return
	old_text = new_text
	# FonctionsGlobal.to_int n'est pas obligatoire car la bdd semble convertir automatiquement, mais on met au cas où
	var id_album = FonctionsGlobal.to_int(get_node("../../id album").text)
	var new_annee = FonctionsGlobal.to_int(new_text)
	var database = get_tree().get_nodes_in_group("database")[0]
	var resultat = database.exec_sql("UPDATE Albums SET annee = ? WHERE id=?", [new_annee, id_album])
	if resultat[0]:
		Notif.add_notif("année de l'album changé")
	else:
		Notif.add_notif("échec du changement de l'année de l'album")

func _on_focus_exited() -> void:
	update_annee(text)

func _ready() -> void:
	old_text = text
