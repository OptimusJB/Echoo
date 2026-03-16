extends CheckBox


func _on_toggled(toggled_on: bool) -> void:
	if toggled_on:
		$"../VBoxContainer/fichiers".visible = true
	else:
		$"../VBoxContainer/fichiers".visible = false
