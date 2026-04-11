extends LineEdit

var old_text

func _ready() -> void:
	old_text = text
	
func _on_text_submitted(new_text: String) -> void:
	# on change la valeur dans les settings
	if new_text != old_text:
		Settings.set_setting("taille envoi fichier", FonctionsGlobal.to_float(new_text))
		Notif.add_notif("taille max de fichier changée")
		old_text = new_text

func _on_focus_exited() -> void:
	_on_text_submitted(text)
