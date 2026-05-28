extends Button

func _on_pressed() -> void:
	RessourceLoad.clear()
	Notif.add_notif(tr("RAM_CLEAR"))
