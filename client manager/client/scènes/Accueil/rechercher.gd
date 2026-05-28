extends LineEdit

signal charger_recherche

func _on_text_changed(_new_text: String) -> void:
	$"timer texte".start()

func _on_timer_texte_timeout() -> void:
	var only_dl = $"../téléchargés".button_pressed
	charger_recherche.emit(text, only_dl)
