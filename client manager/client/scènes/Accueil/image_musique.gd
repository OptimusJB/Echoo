extends TextureRect

signal image_gros_plan


func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_type() && event.is_pressed():
		image_gros_plan.emit(texture)
