extends Button

signal option_choisie

func _on_pressed() -> void:
	# on renvoie un signal avec le texte du bouton (option)
	option_choisie.emit(text)
