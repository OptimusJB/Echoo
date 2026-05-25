extends CheckButton

func _on_toggled(toggled_on: bool) -> void:
	Settings.set_setting("generer mipmaps", int(toggled_on))
