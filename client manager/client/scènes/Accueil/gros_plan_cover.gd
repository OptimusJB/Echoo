extends ColorRect


func _on_image_musique_image_gros_plan(texture_cover) -> void:
	# on affiche l'image
	$"centrage/cover".texture = texture_cover
	visible = true

func _on_gui_input(event: InputEvent) -> void:
	#if event.is_action_type() && event.is_pressed():
	if event is InputEventMouseButton and not event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		visible = false
