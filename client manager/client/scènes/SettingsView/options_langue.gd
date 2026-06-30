extends OptionButton

signal afficher_dl_numbers

func _on_item_selected(index: int) -> void:
	var langues = {0:"fr", 1:"en"}	# index du select
	Settings.set_setting("langue", langues[index])
	TranslationServer.set_locale(langues[index])
	
	afficher_dl_numbers.emit()	# pour mettre à jour la langue (utilisation de tr)
