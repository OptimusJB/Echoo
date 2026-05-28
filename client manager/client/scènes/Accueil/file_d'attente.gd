extends "res://client/scènes/Accueil/resize.gd"
signal afficher_file
signal cacher_file

func _on_toggled(toggled_on: bool) -> void:
	if toggled_on:
		afficher_file.emit()
	else:
		cacher_file.emit()
