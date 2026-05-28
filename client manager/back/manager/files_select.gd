extends FileDialog

var noeud_appelant

func _on_files_selected(paths: PackedStringArray) -> void:
	noeud_appelant.fichiers_choisis.call(paths)
