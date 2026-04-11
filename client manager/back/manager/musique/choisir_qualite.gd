extends Button

@export var qualite:String	# = min, moy ou max
	
func fichier_choisi(chemin_fichier):
	# on change le fichier audio (pas de vérification)
	var id_musique = get_tree().get_nodes_in_group("noeud racine")[0].id
	var database = get_tree().get_nodes_in_group("database")[0]
	var resultat = database.exec_sql("UPDATE Musiques SET " + qualite + " = ? WHERE id=?", [chemin_fichier, id_musique])
	if not resultat[0]:
		Notif.add_notif("échec du changement de musique")
		return
		
	# on change le texte affiché
	$"../".get_child(1).text = chemin_fichier


func _on_pressed() -> void:
	var file_dialog = get_tree().get_nodes_in_group("file dialogs")[2]
	file_dialog.noeud_appelant = self
	file_dialog.popup_file_dialog()
	
