extends LineEdit

signal charger_recherche

func _on_text_changed(_new_text: String) -> void:
	$"timer texte".start()

func _on_timer_texte_timeout() -> void:
	charger_recherche.emit(text)
