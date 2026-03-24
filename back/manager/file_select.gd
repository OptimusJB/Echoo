extends FileDialog

var noeud_appelant

func _on_file_selected(path: String) -> void:
	noeud_appelant.fichier_choisi.call(path)
