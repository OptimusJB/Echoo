extends Button

func _on_pressed() -> void:
	Settings.get_setting("liste blanche ip").erase($"../ip".text)
	Settings.save_settings()
	$"../../".queue_free()
	Notif.add_notif("ip supprimée")
