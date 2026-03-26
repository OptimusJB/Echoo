extends OptionButton

func _on_item_selected(index: int) -> void:
	# on change la prioriété
	Settings.set_setting("mode bannissement", index)
	Notif.add_notif("mode de bannissement changé")
