extends SpinBox


func _on_value_changed(value: float) -> void:
	Settings.set_setting("cache max", int(value))
