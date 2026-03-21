extends CheckBox
signal massive_select
var allow_massive_signal = true

func _on_toggled(toggled_on: bool) -> void:
	if toggled_on:
		$"../infos/fichiers".visible = true
	else:
		$"../infos/fichiers".visible = false
	
	# on check si c'est un shift click
	if Input.is_key_pressed(KEY_SHIFT) and allow_massive_signal:
		massive_select.emit($"../")
	else:
		FonctionsGlobal.start_music_selected = $"../"
	
	if not allow_massive_signal:
		allow_massive_signal = true
