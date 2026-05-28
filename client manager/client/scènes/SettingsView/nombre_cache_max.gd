extends SpinBox


func _on_value_changed(valeur: float) -> void:
	Settings.set_setting("cache max", int(valeur))
