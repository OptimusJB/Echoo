extends CheckButton


func _on_toggled(toggled_on: bool) -> void:
	Settings.set_setting("charger images", int(toggled_on))
