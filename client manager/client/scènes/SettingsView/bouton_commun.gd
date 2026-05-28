extends CheckButton

func _on_toggled(toggled_on: bool) -> void:
	Settings.get_setting("telechargements")["est commun"] = int(toggled_on)
	Settings.save_settings()
