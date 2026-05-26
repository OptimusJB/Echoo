extends OptionButton

func _on_item_selected(index: int) -> void:
	var langues = {0:"fr", 1:"en"}	# index du select
	Settings.set_setting("langue", langues[index])
	TranslationServer.set_locale(langues[index])
