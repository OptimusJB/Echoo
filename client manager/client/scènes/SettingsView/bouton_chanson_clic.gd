extends CheckButton

func _on_toggled(toggled_on: bool) -> void:
	Settings.set_setting("commencer à la chanson cliquee", int(toggled_on))
